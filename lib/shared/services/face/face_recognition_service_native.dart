import 'dart:math' as math;
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Result of a recognition attempt, carrying both similarity metrics for debug.
class RecognitionResult {
  final bool matched;
  final String? employeeId;
  final double similarity;       // cosine similarity [0, 1]
  final double euclideanDist;    // euclidean distance (lower = more similar)

  const RecognitionResult({
    required this.matched,
    this.employeeId,
    required this.similarity,
    this.euclideanDist = 0,
  });
}

/// MobileFaceNet pipeline:
///   Camera frame → MLKit detection → alignment → crop 112×112 → TFLite → embedding 192-dim L2-normalized
///   Matching: cosine similarity (primary) + euclidean distance (debug)
class FaceRecognitionService {
  static final FaceRecognitionService instance = FaceRecognitionService._();
  FaceRecognitionService._();

  Interpreter? _interpreter;
  bool _initialized = false;

  // Cosine similarity threshold for L2-normalized MobileFaceNet embeddings.
  // Range [0,1]. 0.72 is a reasonable starting point; lower to reduce false-rejects,
  // raise to reduce false-accepts.
  static const double _threshold = 0.72;

  static const int _inputSize = 112;
  static const int _embeddingSize = 192;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _interpreter = await Interpreter.fromAsset(
      'assets/models/mobilefacenet.tflite',
    );
    // ignore: avoid_print
    print('[FaceRec] input shape: ${_interpreter!.getInputTensor(0).shape}');
    // ignore: avoid_print
    print('[FaceRec] output shape: ${_interpreter!.getOutputTensor(0).shape}');
    _initialized = true;
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }

  // ── Embedding extraction ──────────────────────────────────────────────────

  /// Extract embedding from a decoded still image + MLKit face object.
  /// Used by enrollment (high-res JPEG) and attendance still-capture fallback.
  Future<List<double>?> extractEmbedding(
    img.Image fullImage,
    Face face,
  ) async {
    if (!_initialized) await init();
    final cropped = _alignAndCrop(fullImage, face);
    if (cropped == null) return null;
    return _runInference(cropped);
  }

  /// Extract embedding from an already-cropped face image (any size → resized internally).
  Future<List<double>?> extractEmbeddingFromCrop(img.Image faceImage) async {
    if (!_initialized) await init();
    final resized = img.copyResize(faceImage, width: _inputSize, height: _inputSize);
    return _runInference(resized);
  }

  /// Convert NV21 camera bytes to img.Image, apply rotation, then crop the detected face.
  /// This avoids the JPEG round-trip of takePicture() and gives sharper crops at low resolution.
  Future<List<double>?> extractEmbeddingFromNv21({
    required Uint8List nv21Bytes,
    required int width,
    required int height,
    required InputImageRotation rotation,
    required Face face,
  }) async {
    if (!_initialized) await init();

    img.Image fullImage = _nv21ToImage(nv21Bytes, width, height);
    fullImage = _applyRotation(fullImage, rotation);

    final cropped = _alignAndCrop(fullImage, face);
    if (cropped == null) return null;
    return _runInference(cropped);
  }

  // ── NV21 helpers (mirrored from reference facedetector.dart) ─────────────

  static img.Image _nv21ToImage(Uint8List nv21, int width, int height) {
    final image = img.Image(width: width, height: height);
    final int ySize = width * height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = ySize + (y >> 1) * width + (x & ~1);

        final int yVal = nv21[yIndex];
        final int vVal = nv21[uvIndex];
        final int uVal = nv21[uvIndex + 1];

        final int r = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
        final int g = (yVal - 0.698001 * (vVal - 128) - 0.337633 * (uVal - 128))
            .round().clamp(0, 255);
        final int b = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }

  static img.Image _applyRotation(img.Image image, InputImageRotation rotation) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return img.copyRotate(image, angle: 90);
      case InputImageRotation.rotation180deg:
        return img.copyRotate(image, angle: 180);
      case InputImageRotation.rotation270deg:
        return img.copyRotate(image, angle: 270);
      case InputImageRotation.rotation0deg:
        return image;
    }
  }

  // ── Alignment & crop ──────────────────────────────────────────────────────

  /// Crop face bounding box with 20% padding and optional eye-landmark rotation.
  img.Image? _alignAndCrop(img.Image src, Face face) {
    final box = face.boundingBox;

    final padding = (box.width * 0.2).toInt();
    final x = (box.left - padding).clamp(0, src.width - 1).toInt();
    final y = (box.top - padding).clamp(0, src.height - 1).toInt();
    final w = (box.width + padding * 2).clamp(1, src.width - x).toInt();
    final h = (box.height + padding * 2).clamp(1, src.height - y).toInt();

    if (w <= 0 || h <= 0) return null;

    img.Image cropped = img.copyCrop(src, x: x, y: y, width: w, height: h);

    // Eye-landmark alignment: only available when landmarks are enabled on the detector.
    // Skip silently if landmarks are absent (e.g., fast-mode without landmark option).
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye != null && rightEye != null) {
      final dx = rightEye.position.x - leftEye.position.x;
      final dy = rightEye.position.y - leftEye.position.y;
      final angle = math.atan2(dy.toDouble(), dx.toDouble()) * 180 / math.pi;
      if (angle.abs() > 2.0) {
        cropped = img.copyRotate(cropped, angle: -angle);
      }
    }

    return img.copyResize(cropped, width: _inputSize, height: _inputSize);
  }

  // ── TFLite inference ──────────────────────────────────────────────────────

  List<double> _runInference(img.Image face112) {
    // MobileFaceNet: NHWC float32, RGB, normalized to [-1, 1]
    final Float32List flatInput = Float32List(_inputSize * _inputSize * 3);
    int idx = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final p = face112.getPixel(x, y);
        flatInput[idx++] = (p.r.toDouble() - 127.5) / 127.5;
        flatInput[idx++] = (p.g.toDouble() - 127.5) / 127.5;
        flatInput[idx++] = (p.b.toDouble() - 127.5) / 127.5;
      }
    }

    // reshape() is a List extension from tflite_flutter, not on Float32List
    final input = flatInput.toList().reshape([1, _inputSize, _inputSize, 3]);
    final output = [List.filled(_embeddingSize, 0.0)];

    _interpreter!.run(input, output);

    final raw = (output[0] as List).map((e) => (e as num).toDouble()).toList();
    return _normalizeEmbedding(raw);
  }

  // ── Matching ──────────────────────────────────────────────────────────────

  /// Compare query embedding against stored embeddings.
  /// Returns cosine similarity as primary metric; euclidean distance for debug.
  RecognitionResult findBestMatch(
    List<double> queryEmbedding,
    Map<String, List<double>> storedEmbeddings,
  ) {
    if (storedEmbeddings.isEmpty) {
      return const RecognitionResult(matched: false, similarity: 0, euclideanDist: 0);
    }

    String? bestId;
    double bestCosine = -1;
    double bestEuclidean = double.infinity;

    for (final entry in storedEmbeddings.entries) {
      final cosine = cosineSimilarity(queryEmbedding, entry.value);
      final eucl = euclideanDistance(queryEmbedding, entry.value);
      if (cosine > bestCosine) {
        bestCosine = cosine;
        bestEuclidean = eucl;
        bestId = entry.key;
      }
    }

    final matched = bestCosine >= _threshold;

    // ignore: avoid_print
    print('[FaceRec] cosine=${bestCosine.toStringAsFixed(4)}  '
        'euclidean=${bestEuclidean.toStringAsFixed(4)}  '
        'matched=$matched  threshold=$_threshold');

    return RecognitionResult(
      matched: matched,
      employeeId: matched ? bestId : null,
      similarity: bestCosine.clamp(0.0, 1.0),
      euclideanDist: bestEuclidean,
    );
  }

  // ── Static helpers ────────────────────────────────────────────────────────

  static double euclideanDistance(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Embedding mismatch: ${a.length} != ${b.length}');
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return math.sqrt(sum);
  }

  static double cosineSimilarity(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Embedding mismatch: ${a.length} != ${b.length}');
    double dot = 0;
    double normA = 0;
    double normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    if (denom == 0) return 0;
    return (dot / denom).clamp(-1.0, 1.0);
  }

  /// Average multiple embeddings then L2-normalize.
  /// Used for multi-angle enrollment averaging.
  static List<double> averageEmbeddings(List<List<double>> embeddings) {
    assert(embeddings.isNotEmpty);
    final size = embeddings.first.length;
    final avg = List.filled(size, 0.0);
    for (final e in embeddings) {
      for (int i = 0; i < size; i++) {
        avg[i] += e[i];
      }
    }
    for (int i = 0; i < size; i++) {
      avg[i] /= embeddings.length;
    }
    return _normalizeEmbedding(avg);
  }

  /// Select the embedding with the highest L2 norm before normalization —
  /// a proxy for "most confident" model output.
  static List<double> bestEmbedding(List<List<double>> embeddings) {
    assert(embeddings.isNotEmpty);
    // embeddings here are already normalized (norm ≈ 1), so pick by
    // cosine similarity to the group centroid (most representative sample).
    final centroid = averageEmbeddings(embeddings);
    List<double>? best;
    double bestSim = -1;
    for (final e in embeddings) {
      final sim = cosineSimilarity(e, centroid);
      if (sim > bestSim) {
        bestSim = sim;
        best = e;
      }
    }
    return best!;
  }

  static List<double> normalizeEmbedding(List<double> embedding) =>
      _normalizeEmbedding(embedding);

  static List<double> _normalizeEmbedding(List<double> v) {
    double norm = 0;
    for (final x in v) {
      norm += x * x;
    }
    norm = math.sqrt(norm);
    if (norm == 0) return List<double>.from(v);
    return v.map((x) => x / norm).toList(growable: false);
  }

  double get threshold => _threshold;
  bool get isInitialized => _initialized;
}
