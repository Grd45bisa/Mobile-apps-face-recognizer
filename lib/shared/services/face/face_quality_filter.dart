import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Result of a quality check on a single camera frame.
class FrameQualityResult {
  final bool accepted;
  final double score;       // 0.0 – 1.0, higher = better
  final String? rejectReason;

  const FrameQualityResult({
    required this.accepted,
    required this.score,
    this.rejectReason,
  });
}

/// Stateless utility that scores and filters face frames before embedding
/// extraction. All thresholds are tunable constants at the top of the class.
class FaceQualityFilter {
  // ── Thresholds ─────────────────────────────────────────────────────────────

  /// Minimum face bounding-box size relative to the full image's shorter side.
  static const double _minFaceSizeRatio = 0.12;

  /// Laplacian variance thresholds for blur detection (higher = sharper).
  static const double _minSharpness = 60.0;

  /// Pixel brightness range [0, 255] for the cropped face region.
  static const double _minBrightness = 40.0;
  static const double _maxBrightness = 230.0;

  /// Maximum absolute head-tilt angle (degrees) from eye landmarks.
  /// Used only when landmarks are available; skipped otherwise.
  static const double _maxTiltDegrees = 30.0;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Lightweight check for live streaming — no pixel decoding needed.
  /// Only checks face size relative to frame dimensions and head tilt.
  /// Use this in the camera stream to avoid blocking the UI thread.
  static FrameQualityResult evaluateFast(
    Face face,
    int frameWidth,
    int frameHeight,
  ) {
    final box = face.boundingBox;
    final shorter = frameWidth < frameHeight ? frameWidth : frameHeight;
    final faceSize = box.width < box.height ? box.width : box.height;

    if (faceSize / shorter < _minFaceSizeRatio) {
      return const FrameQualityResult(
        accepted: false,
        score: 0,
        rejectReason: 'Wajah terlalu jauh dari kamera',
      );
    }

    double tilt = 0;
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye != null && rightEye != null) {
      final dx = (rightEye.position.x - leftEye.position.x).toDouble();
      final dy = (rightEye.position.y - leftEye.position.y).toDouble();
      tilt = _atan2Degrees(dy, dx).abs();
      if (tilt > _maxTiltDegrees) {
        return FrameQualityResult(
          accepted: false,
          score: 0,
          rejectReason: 'Kepala terlalu miring',
        );
      }
    }

    final sizeScore = (faceSize / shorter / 0.5).clamp(0.0, 1.0);
    final tiltScore = tilt > 0
        ? (1.0 - tilt / _maxTiltDegrees).clamp(0.0, 1.0)
        : 1.0;
    final score = (sizeScore * 0.6 + tiltScore * 0.4).clamp(0.0, 1.0);

    return FrameQualityResult(accepted: true, score: score);
  }

  /// Full evaluate with pixel-level checks (brightness + sharpness).
  /// Use this during enrollment where accuracy matters more than speed.
  static FrameQualityResult evaluate(img.Image fullImage, Face face) {
    final box = face.boundingBox;
    final shorter = fullImage.width < fullImage.height
        ? fullImage.width
        : fullImage.height;

    // 1. Face size
    final faceSize = box.width < box.height ? box.width : box.height;
    if (faceSize / shorter < _minFaceSizeRatio) {
      return const FrameQualityResult(
        accepted: false,
        score: 0,
        rejectReason: 'Wajah terlalu jauh dari kamera',
      );
    }

    // 2. Crop the face region (clamped to image bounds)
    final x = box.left.toInt().clamp(0, fullImage.width - 1);
    final y = box.top.toInt().clamp(0, fullImage.height - 1);
    final w = box.width.toInt().clamp(1, fullImage.width - x);
    final h = box.height.toInt().clamp(1, fullImage.height - y);
    final faceCrop = img.copyCrop(fullImage, x: x, y: y, width: w, height: h);

    // 3. Brightness check (mean luminance of face crop)
    final brightness = _meanBrightness(faceCrop);
    if (brightness < _minBrightness) {
      return const FrameQualityResult(
        accepted: false,
        score: 0,
        rejectReason: 'Pencahayaan terlalu gelap',
      );
    }
    if (brightness > _maxBrightness) {
      return const FrameQualityResult(
        accepted: false,
        score: 0,
        rejectReason: 'Pencahayaan terlalu terang',
      );
    }

    // 4. Sharpness (Laplacian variance on grayscale crop)
    final sharpness = _laplacianVariance(faceCrop);
    if (sharpness < _minSharpness) {
      return FrameQualityResult(
        accepted: false,
        score: 0,
        rejectReason:
            'Gambar terlalu blur (${sharpness.toStringAsFixed(1)})',
      );
    }

    // 5. Head tilt (optional — requires landmark data)
    double tilt = 0;
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye != null && rightEye != null) {
      final dx = (rightEye.position.x - leftEye.position.x).toDouble();
      final dy = (rightEye.position.y - leftEye.position.y).toDouble();
      tilt = _atan2Degrees(dy, dx).abs();
      if (tilt > _maxTiltDegrees) {
        return FrameQualityResult(
          accepted: false,
          score: 0,
          rejectReason:
              'Kepala terlalu miring (${tilt.toStringAsFixed(0)}°)',
        );
      }
    }

    // 6. Composite score (weighted combination, all normalized to [0,1])
    final sizeScore = (faceSize / shorter / 0.5).clamp(0.0, 1.0);
    final sharpScore = (sharpness / 300.0).clamp(0.0, 1.0);
    final brightMid = 128.0;
    final brightScore =
        (1.0 - ((brightness - brightMid) / brightMid).abs()).clamp(0.0, 1.0);
    final tiltScore = tilt > 0
        ? (1.0 - tilt / _maxTiltDegrees).clamp(0.0, 1.0)
        : 1.0;

    final score = (sizeScore * 0.25 +
            sharpScore * 0.40 +
            brightScore * 0.20 +
            tiltScore * 0.15)
        .clamp(0.0, 1.0);

    return FrameQualityResult(accepted: true, score: score);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static double _meanBrightness(img.Image image) {
    double sum = 0;
    final total = image.width * image.height;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        // Luminance approximation: 0.299R + 0.587G + 0.114B
        sum += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      }
    }
    return sum / total;
  }

  /// Laplacian variance — proxy for sharpness. Higher = sharper.
  static double _laplacianVariance(img.Image image) {
    // Work on a downscaled copy for speed (max 64px on the shorter side)
    final scale = 64 / (image.width < image.height ? image.width : image.height);
    final small = scale < 1.0
        ? img.copyResize(
            image,
            width: (image.width * scale).round(),
            height: (image.height * scale).round(),
          )
        : image;

    final w = small.width;
    final h = small.height;
    if (w < 3 || h < 3) return 0;

    // Build grayscale map
    final gray = List.generate(h, (y) {
      return List.generate(w, (x) {
        final p = small.getPixel(x, y);
        return (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
      });
    });

    // Apply 3×3 Laplacian kernel: [0,1,0, 1,-4,1, 0,1,0]
    double mean = 0;
    double mean2 = 0;
    int count = 0;
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final lap = gray[y - 1][x] +
            gray[y + 1][x] +
            gray[y][x - 1] +
            gray[y][x + 1] -
            4 * gray[y][x];
        mean += lap;
        mean2 += lap * lap;
        count++;
      }
    }
    if (count == 0) return 0;
    mean /= count;
    mean2 /= count;
    return mean2 - mean * mean; // variance
  }

  static double _atan2Degrees(double y, double x) {
    const radToDeg = 180.0 / 3.141592653589793;
    return _atan2(y, x) * radToDeg;
  }

  // Dart's math.atan2 is in dart:math — replicate inline to keep this file
  // free of additional imports.
  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  // Taylor-series atan (sufficient precision for degree-level tilt check)
  static double _atan(double z) {
    // Range-reduce to |z| <= 1
    if (z.abs() > 1) {
      return (z > 0 ? 1 : -1) * 3.141592653589793 / 2 - _atan(1 / z);
    }
    final z2 = z * z;
    return z *
        (1 -
            z2 / 3 +
            z2 * z2 / 5 -
            z2 * z2 * z2 / 7 +
            z2 * z2 * z2 * z2 / 9);
  }
}
