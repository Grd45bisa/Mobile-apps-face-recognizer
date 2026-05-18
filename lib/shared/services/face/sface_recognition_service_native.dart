import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'face_quality_filter.dart';
import 'face_recognition_service.dart';

class SFaceRecognitionService {
  static final SFaceRecognitionService instance = SFaceRecognitionService._();
  SFaceRecognitionService._();

  static const String _modelAsset = 'assets/models/sface.tflite';

  Interpreter? _interpreter;
  int _inputSize = 112;
  bool _nchw = false;
  bool _uint8Input = false;
  bool _initialized = false;
  Future<void>? _initFuture;
  int _outputIndex = 0;
  List<int> _outputShape = const [1, 128];
  String? _lastError;

  String? get lastError => _lastError;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    final running = _initFuture;
    if (running != null) return running;
    _initFuture = _init();
    return _initFuture;
  }

  Future<void> _init() async {
    try {
      final interpreter = await Interpreter.fromAsset(_modelAsset);
      final inputTensor = interpreter.getInputTensor(0);
      final inputShape = inputTensor.shape;
      final outputTensors = interpreter.getOutputTensors();
      _outputIndex = _selectEmbeddingOutputIndex(outputTensors);
      _outputShape = List<int>.from(
        interpreter.getOutputTensor(_outputIndex).shape,
      );
      _uint8Input = inputTensor.type == TensorType.uint8;

      if (inputShape.length == 4) {
        _nchw = inputShape[1] == 3;
        _inputSize = _nchw ? inputShape[2] : inputShape[1];
      }

      _interpreter = interpreter;
      _initialized = true;
      _lastError = null;
      // ignore: avoid_print
      print(
        '[SFace] loaded input=$inputShape type=${inputTensor.type} '
        'outputIndex=$_outputIndex output=$_outputShape '
        'outputs=${_describeOutputs(outputTensors)} '
        'nchw=$_nchw',
      );
    } catch (e) {
      _lastError = e.toString();
      // ignore: avoid_print
      print('[SFace] failed to load: $e');
      rethrow;
    } finally {
      _initFuture = null;
    }
  }

  Future<List<double>?> extractEmbeddingFromCrop(img.Image faceImage) async {
    if (!_initialized) await init();
    final resized = img.copyResize(
      faceImage,
      width: _inputSize,
      height: _inputSize,
    );
    return _runInference(resized);
  }

  Future<List<double>?> extractEmbeddingFromNv21({
    required Uint8List nv21Bytes,
    required int width,
    required int height,
    required InputImageRotation rotation,
    required Face face,
    bool enforceQuality = true,
  }) async {
    if (!_initialized) await init();

    if (enforceQuality) {
      final quality = FaceQualityFilter.evaluateFast(face, width, height);
      if (!quality.accepted) {
        throw QualityFilterException(
          quality.rejectReason ?? 'Kualitas wajah buruk',
        );
      }
    }

    final box = face.boundingBox;
    final padding = (box.width * 0.5).toInt();
    final cropX = (box.left - padding).clamp(0, width - 1).toInt();
    final cropY = (box.top - padding).clamp(0, height - 1).toInt();
    final cropW = (box.width + padding * 2).clamp(1, width - cropX).toInt();
    final cropH = (box.height + padding * 2).clamp(1, height - cropY).toInt();

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    final faceImage = await compute(
      _nv21CropToImage,
      _SFaceNv21CropParams(
        nv21: nv21Bytes,
        frameWidth: width,
        frameHeight: height,
        cropX: cropX,
        cropY: cropY,
        cropW: cropW,
        cropH: cropH,
        rotation: rotation,
        inputSize: _inputSize,
        leX: leftEye?.position.x.toDouble(),
        leY: leftEye?.position.y.toDouble(),
        reX: rightEye?.position.x.toDouble(),
        reY: rightEye?.position.y.toDouble(),
      ),
    );

    if (faceImage == null) return null;
    return _runInference(faceImage);
  }

  List<double>? _runInference(img.Image faceImage) {
    final interpreter = _interpreter;
    if (interpreter == null) return null;

    final input = _uint8Input
        ? (_nchw ? _nchwInputUint8(faceImage) : _nhwcInputUint8(faceImage))
        : (_nchw ? _nchwInputFloat(faceImage) : _nhwcInputFloat(faceImage));
    final output = _makeOutputBuffer(_outputShape);

    try {
      final stopwatch = kDebugMode ? (Stopwatch()..start()) : null;
      interpreter.runInference([input]);
      interpreter.getOutputTensor(_outputIndex).copyTo(output);
      if (stopwatch != null) {
        stopwatch.stop();
        // ignore: avoid_print
        print('[SFace] inference: ${stopwatch.elapsedMilliseconds} ms');
      }

      final embedding = _flattenOutput(output);
      if (embedding.isEmpty) {
        _lastError = 'Output SFace kosong.';
        return null;
      }
      _lastError = null;
      return _normalize(embedding);
    } catch (e) {
      _lastError = e.toString();
      // ignore: avoid_print
      print('[SFace] inference failed: $e');
      return null;
    }
  }

  List<List<List<List<double>>>> _nhwcInputFloat(img.Image image) {
    return [
      List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final p = image.getPixel(x, y);
          return [
            (p.r.toDouble() - 127.5) / 127.5,
            (p.g.toDouble() - 127.5) / 127.5,
            (p.b.toDouble() - 127.5) / 127.5,
          ];
        });
      }),
    ];
  }

  List<List<List<List<double>>>> _nchwInputFloat(img.Image image) {
    return [
      List.generate(3, (channel) {
        return List.generate(_inputSize, (y) {
          return List.generate(_inputSize, (x) {
            final p = image.getPixel(x, y);
            final value = switch (channel) {
              0 => p.r,
              1 => p.g,
              _ => p.b,
            };
            return (value.toDouble() - 127.5) / 127.5;
          });
        });
      }),
    ];
  }

  List<List<List<List<int>>>> _nhwcInputUint8(img.Image image) {
    return [
      List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final p = image.getPixel(x, y);
          return [p.r.toInt(), p.g.toInt(), p.b.toInt()];
        });
      }),
    ];
  }

  List<List<List<List<int>>>> _nchwInputUint8(img.Image image) {
    return [
      List.generate(3, (channel) {
        return List.generate(_inputSize, (y) {
          return List.generate(_inputSize, (x) {
            final p = image.getPixel(x, y);
            final value = switch (channel) {
              0 => p.r,
              1 => p.g,
              _ => p.b,
            };
            return value.toInt();
          });
        });
      }),
    ];
  }

  dynamic _makeOutputBuffer(List<int> shape) {
    if (shape.isEmpty) return 0.0;
    if (shape.length == 1) return List<double>.filled(shape.first, 0.0);
    return List.generate(
      shape.first,
      (_) => _makeOutputBuffer(shape.sublist(1)),
    );
  }

  List<double> _flattenOutput(dynamic value) {
    final result = <double>[];

    void visit(dynamic node) {
      if (node is num) {
        result.add(node.toDouble());
      } else if (node is Iterable) {
        for (final child in node) {
          visit(child);
        }
      }
    }

    visit(value);
    return result;
  }

  static int _selectEmbeddingOutputIndex(List<Tensor> tensors) {
    if (tensors.isNotEmpty && _looksLikeEmbeddingOutput(tensors.first)) {
      // SFace lab memakai output 0. Pertahankan itu sebagai default agar hasil
      // presensi/daftar konsisten dengan screen profile.
      return 0;
    }

    var bestIndex = 0;
    var bestElements = -1;
    for (int i = 0; i < tensors.length; i++) {
      final tensor = tensors[i];
      final elements = tensor.numElements();

      if (_looksLikeEmbeddingOutput(tensor) && elements > bestElements) {
        bestIndex = i;
        bestElements = elements;
      }
    }
    return bestIndex;
  }

  static bool _looksLikeEmbeddingOutput(Tensor tensor) {
    final elements = tensor.numElements();
    final shape = tensor.shape;
    return (elements == 128 || elements == 256 || elements == 512) &&
        shape.isNotEmpty &&
        shape.length <= 4 &&
        tensor.type != TensorType.string &&
        tensor.type != TensorType.boolean;
  }

  static String _describeOutputs(List<Tensor> tensors) {
    return List.generate(tensors.length, (i) {
      final tensor = tensors[i];
      return '#$i:${tensor.shape}/${tensor.type}/${tensor.numElements()}';
    }).join(',');
  }

  static List<double> _normalize(List<double> embedding) {
    double sum = 0;
    for (final value in embedding) {
      sum += value * value;
    }
    final norm = math.sqrt(sum);
    if (norm == 0) return List<double>.from(embedding);
    return embedding.map((value) => value / norm).toList(growable: false);
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }
}

img.Image? _nv21CropToImage(_SFaceNv21CropParams p) {
  final ySize = p.frameWidth * p.frameHeight;
  final raw = img.Image(width: p.cropW, height: p.cropH);

  for (int cy = 0; cy < p.cropH; cy++) {
    final fy = p.cropY + cy;
    for (int cx = 0; cx < p.cropW; cx++) {
      final fx = p.cropX + cx;
      final yIndex = fy * p.frameWidth + fx;
      final uvIndex = ySize + (fy >> 1) * p.frameWidth + (fx & ~1);
      if (yIndex >= ySize || uvIndex + 1 >= p.nv21.length) continue;

      final yVal = p.nv21[yIndex];
      final vVal = p.nv21[uvIndex];
      final uVal = p.nv21[uvIndex + 1];

      final r = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
      final g = (yVal - 0.698001 * (vVal - 128) - 0.337633 * (uVal - 128))
          .round()
          .clamp(0, 255);
      final b = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);
      raw.setPixelRgb(cx, cy, r, g, b);
    }
  }

  final img.Image rotated;
  switch (p.rotation) {
    case InputImageRotation.rotation90deg:
      rotated = img.copyRotate(raw, angle: 90);
    case InputImageRotation.rotation180deg:
      rotated = img.copyRotate(raw, angle: 180);
    case InputImageRotation.rotation270deg:
      rotated = img.copyRotate(raw, angle: 270);
    case InputImageRotation.rotation0deg:
      rotated = raw;
  }

  if (p.leX != null && p.leY != null && p.reX != null && p.reY != null) {
    double mapX(double fx, double fy) {
      final cx2 = fx - p.cropX;
      final cy2 = fy - p.cropY;
      switch (p.rotation) {
        case InputImageRotation.rotation90deg:
          return (p.cropH - 1) - cy2;
        case InputImageRotation.rotation180deg:
          return (p.cropW - 1) - cx2;
        case InputImageRotation.rotation270deg:
          return cy2.toDouble();
        case InputImageRotation.rotation0deg:
          return cx2.toDouble();
      }
    }

    double mapY(double fx, double fy) {
      final cx2 = fx - p.cropX;
      final cy2 = fy - p.cropY;
      switch (p.rotation) {
        case InputImageRotation.rotation90deg:
          return cx2.toDouble();
        case InputImageRotation.rotation180deg:
          return (p.cropH - 1) - cy2;
        case InputImageRotation.rotation270deg:
          return (p.cropW - 1) - cx2;
        case InputImageRotation.rotation0deg:
          return cy2.toDouble();
      }
    }

    final leXr = mapX(p.leX!, p.leY!);
    final leYr = mapY(p.leX!, p.leY!);
    final reXr = mapX(p.reX!, p.reY!);
    final reYr = mapY(p.reX!, p.reY!);

    final dx = reXr - leXr;
    final dy = reYr - leYr;
    final angle = math.atan2(dy, dx) * 180 / math.pi;
    final aligned = angle.abs() > 1.0
        ? img.copyRotate(rotated, angle: -angle)
        : rotated;

    final cosA = math.cos(-angle * math.pi / 180);
    final sinA = math.sin(-angle * math.pi / 180);
    final imgCx = rotated.width / 2.0;
    final imgCy = rotated.height / 2.0;

    double rot(double px, double py, bool isX) {
      final rx = cosA * (px - imgCx) - sinA * (py - imgCy) + imgCx;
      final ry = sinA * (px - imgCx) + cosA * (py - imgCy) + imgCy;
      return isX ? rx : ry;
    }

    final mX = (rot(leXr, leYr, true) + rot(reXr, reYr, true)) / 2.0;
    final mY = (rot(leXr, leYr, false) + rot(reXr, reYr, false)) / 2.0;
    final eyeDist = (rot(reXr, reYr, true) - rot(leXr, leYr, true)).abs();

    if (eyeDist >= 4) {
      final cropSize = (eyeDist * 3.5).round();
      final x = (mX - cropSize / 2.0).round().clamp(0, aligned.width - 1);
      final y = (mY - cropSize * 0.38).round().clamp(0, aligned.height - 1);
      final w = cropSize.clamp(1, aligned.width - x);
      final h = cropSize.clamp(1, aligned.height - y);
      if (w >= 20 && h >= 20) {
        final face = img.copyCrop(aligned, x: x, y: y, width: w, height: h);
        return img.copyResize(face, width: p.inputSize, height: p.inputSize);
      }
    }
  }

  return img.copyResize(rotated, width: p.inputSize, height: p.inputSize);
}

class _SFaceNv21CropParams {
  final Uint8List nv21;
  final int frameWidth;
  final int frameHeight;
  final int cropX;
  final int cropY;
  final int cropW;
  final int cropH;
  final InputImageRotation rotation;
  final int inputSize;
  final double? leX;
  final double? leY;
  final double? reX;
  final double? reY;

  const _SFaceNv21CropParams({
    required this.nv21,
    required this.frameWidth,
    required this.frameHeight,
    required this.cropX,
    required this.cropY,
    required this.cropW,
    required this.cropH,
    required this.rotation,
    required this.inputSize,
    this.leX,
    this.leY,
    this.reX,
    this.reY,
  });
}
