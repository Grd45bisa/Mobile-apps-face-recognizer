import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../shared/services/auth_service.dart';
import '../../../shared/services/face/embedding_sync_service.dart';
import '../../../shared/services/face/face_quality_filter.dart';
import '../../../shared/services/face/face_recognition_service.dart';
import '../../../shared/theme/app_colors.dart';

class FaceAiLabScreen extends StatefulWidget {
  const FaceAiLabScreen({super.key});

  @override
  State<FaceAiLabScreen> createState() => _FaceAiLabScreenState();
}

class _FaceAiLabScreenState extends State<FaceAiLabScreen> {
  final _picker = ImagePicker();
  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: false,
    ),
  );

  bool _busy = false;
  _LabResult? _result;

  @override
  void initState() {
    super.initState();
    FaceRecognitionService.instance.init();
  }

  @override
  void dispose() {
    _detector.close();
    super.dispose();
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _result = null;
    });

    try {
      final uid = AuthService.instance.currentUserId;
      if (uid == null) {
        _showSnack('Sesi tidak ditemukan.');
        return;
      }

      final stored = await EmbeddingSyncService.instance.getEmbeddings(uid);
      if (stored == null || stored.isEmpty) {
        _showSnack('Daftarkan wajah terlebih dahulu sebelum membuka lab.');
        return;
      }

      final picked = await _picker.pickImage(source: source, imageQuality: 95);
      if (picked == null) return;

      final analysis = await _analyzeImage(picked, stored);
      if (!mounted) return;
      setState(() => _result = analysis);
    } catch (e) {
      _showSnack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_LabResult> _analyzeImage(
    XFile file,
    List<List<double>> storedEmbeddings,
  ) async {
    final bytes = await file.readAsBytes();
    final decodedRaw = img.decodeImage(bytes);
    final decoded = decodedRaw == null ? null : img.bakeOrientation(decodedRaw);
    if (decoded == null) {
      return _LabResult.error(file, 'File gambar tidak terbaca.');
    }

    final faces = await _detector.processImage(InputImage.fromFilePath(file.path));
    if (faces.isEmpty) {
      return _LabResult.error(file, 'Wajah tidak terdeteksi.', image: decoded);
    }
    if (faces.length > 1) {
      return _LabResult.error(
        file,
        'Terdeteksi lebih dari satu wajah.',
        image: decoded,
      );
    }

    final face = faces.first;
    final quality = FaceQualityFilter.evaluate(decoded, face);
    if (!quality.accepted) {
      return _LabResult.error(
        file,
        quality.rejectReason ?? 'Kualitas foto uji belum cukup baik.',
        image: decoded,
        face: face,
        quality: quality,
      );
    }

    final stopwatch = Stopwatch()..start();
    final query = await FaceRecognitionService.instance.extractEmbedding(
      decoded,
      face,
    );
    stopwatch.stop();

    if (query == null || query.isEmpty) {
      return _LabResult.error(
        file,
        'Embedding foto uji gagal dibuat.',
        image: decoded,
        face: face,
        quality: quality,
      );
    }
    if (storedEmbeddings.any((stored) => query.length != stored.length)) {
      return _LabResult.error(
        file,
        'Dimensi embedding berbeda. Daftarkan ulang wajah.',
        image: decoded,
        face: face,
        quality: quality,
      );
    }

    final match = _bestStoredMatch(query, storedEmbeddings);
    return _LabResult(
      file: file,
      image: decoded,
      face: face,
      quality: quality,
      similarity: match.similarity.clamp(0.0, 1.0),
      euclideanDistance: match.distance,
      inferenceMs: stopwatch.elapsedMilliseconds,
      bestTarget: match.label,
    );
  }

  _StoredMatch _bestStoredMatch(
    List<double> query,
    List<List<double>> storedEmbeddings,
  ) {
    double bestSimilarity = -1;
    double bestDistance = double.infinity;
    int bestIndex = 0;

    for (int i = 0; i < storedEmbeddings.length; i++) {
      final stored = storedEmbeddings[i];
      final similarity = FaceRecognitionService.cosineSimilarity(query, stored);
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestDistance = FaceRecognitionService.euclideanDistance(query, stored);
        bestIndex = i;
      }
    }

    return _StoredMatch(
      similarity: bestSimilarity,
      distance: bestDistance,
      label: switch (bestIndex) {
        0 => 'Frontal avg',
        1 => 'Frontal best',
        2 => 'Kiri avg',
        3 => 'Kiri best',
        4 => 'Kanan avg',
        5 => 'Kanan best',
        _ => 'Embedding ${bestIndex + 1}',
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _errorMessage(Object error) {
    if (error is PlatformException && error.code == 'channel-error') {
      return 'Picker foto belum aktif. Tutup app total lalu jalankan ulang.';
    }
    return 'Gagal menganalisis foto: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Face AI Lab'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _introCard(),
          const SizedBox(height: 14),
          _actionCard(),
          const SizedBox(height: 14),
          if (_busy) const LinearProgressIndicator(minHeight: 3),
          if (_result != null) ...[
            if (_busy) const SizedBox(height: 14),
            _resultCard(_result!),
          ],
        ],
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: const Text(
        'Lab ini memakai embedding hasil daftar wajah sebagai data target. '
        'Pilih foto uji dari galeri atau kamera untuk melihat similarity, '
        'quality gate, pose, ukuran wajah, dan sensitivitas threshold.',
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _actionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _pickAndAnalyze(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Galeri'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _pickAndAnalyze(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('Kamera'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(_LabResult result) {
    final ok = result.error == null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _thumb(result),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ok ? 'Analisis selesai' : 'Analisis gagal',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ok
                          ? 'Similarity ${(result.similarity! * 100).toStringAsFixed(1)}%'
                          : result.error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: ok ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (ok) ...[
            _thresholds(result.similarity!),
            const SizedBox(height: 12),
            _metricGrid(result),
          ] else if (result.face != null || result.quality != null) ...[
            _metricGrid(result),
          ],
        ],
      ),
    );
  }

  Widget _thumb(_LabResult result) {
    final image = result.image;
    final bytes = image == null
        ? null
        : Uint8List.fromList(img.encodeJpg(image, quality: 82));
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: bytes == null
          ? Image.file(
              File(result.file.path),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            )
          : Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover),
    );
  }

  Widget _thresholds(double similarity) {
    const thresholds = [
      (0.65, 'Longgar'),
      (0.70, 'Sedang'),
      (0.75, 'Ketat'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: thresholds.map((entry) {
        final passed = similarity >= entry.$1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: passed ? AppColors.successLight : AppColors.errorLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${entry.$2} ${entry.$1.toStringAsFixed(2)}: ${passed ? 'Lolos' : 'Gagal'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: passed ? AppColors.success : AppColors.error,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _metricGrid(_LabResult result) {
    final face = result.face;
    final box = face?.boundingBox;
    final metrics = [
      ('Quality', result.quality == null
          ? '-'
          : '${(result.quality!.score * 100).toStringAsFixed(0)}%'),
      ('Pose X', _deg(face?.headEulerAngleX)),
      ('Pose Y', _deg(face?.headEulerAngleY)),
      ('Pose Z', _deg(face?.headEulerAngleZ)),
      ('Face size', box == null
          ? '-'
          : '${box.width.toStringAsFixed(0)} x ${box.height.toStringAsFixed(0)} px'),
      ('Inference', result.inferenceMs == null ? '-' : '${result.inferenceMs} ms'),
      ('Distance', result.euclideanDistance == null
          ? '-'
          : result.euclideanDistance!.toStringAsFixed(3)),
      ('Best target', result.bestTarget ?? '-'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics
          .map(
            (metric) => Container(
              width: 150,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    metric.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    );
  }

  static String _deg(double? value) =>
      value == null ? '-' : '${value.toStringAsFixed(1)} deg';
}

class _LabResult {
  const _LabResult({
    required this.file,
    this.image,
    this.face,
    this.quality,
    this.similarity,
    this.euclideanDistance,
    this.inferenceMs,
    this.bestTarget,
    this.error,
  });

  factory _LabResult.error(
    XFile file,
    String error, {
    img.Image? image,
    Face? face,
    FrameQualityResult? quality,
  }) {
    return _LabResult(
      file: file,
      image: image,
      face: face,
      quality: quality,
      error: error,
    );
  }

  final XFile file;
  final img.Image? image;
  final Face? face;
  final FrameQualityResult? quality;
  final double? similarity;
  final double? euclideanDistance;
  final int? inferenceMs;
  final String? bestTarget;
  final String? error;
}

class _StoredMatch {
  const _StoredMatch({
    required this.similarity,
    required this.distance,
    required this.label,
  });

  final double similarity;
  final double distance;
  final String label;
}
