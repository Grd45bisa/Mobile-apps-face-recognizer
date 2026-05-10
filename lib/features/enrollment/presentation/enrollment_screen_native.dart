import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/face/face_recognition_service.dart';
import '../../../shared/services/face/embedding_sync_service.dart';
import '../../../shared/theme/app_colors.dart';

enum _EnrollStep { capture, processing, done, error }

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen>
    with WidgetsBindingObserver {
  CameraController? _camCtrl;
  _EnrollStep _step = _EnrollStep.capture;
  String? _errorMsg;

  final _detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );

  bool _capturing = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    FaceRecognitionService.instance.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _camCtrl?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty || !mounted || _disposed) return;

    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final ctrl = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await ctrl.initialize();
    if (!mounted || _disposed) {
      ctrl.dispose();
      return;
    }

    // Gunakan auto exposure dan auto focus.
    try {
      await ctrl.setExposureMode(ExposureMode.auto);
      await ctrl.setExposureOffset(0.0);
    } catch (_) {}
    try {
      await ctrl.setFocusMode(FocusMode.auto);
    } catch (_) {}

    setState(() => _camCtrl = ctrl);
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _detector.close();
    _camCtrl?.dispose();
    FaceRecognitionService.instance.dispose();
    super.dispose();
  }

  // ── Multi-frame capture ───────────────────────────────────────────────────

  /// Tap "Ambil Foto" -> ambil satu foto, crop wajah, simpan satu embedding.
  /// filter kualitas tiap frame, simpan embedding dengan skor tertinggi.
  Future<void> _capture() async {
    if (_capturing || _camCtrl == null) return;
    setState(() => _capturing = true);

    try {
      final xFile = await _camCtrl!.takePicture();
      final bytes = await File(xFile.path).readAsBytes();
      final fullImage = img.decodeImage(bytes);
      if (fullImage == null) {
        _showSnack('Gagal membaca foto. Coba lagi.');
        return;
      }

      final inputImage = InputImage.fromFilePath(xFile.path);
      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty) {
        _showSnack('Wajah tidak terdeteksi. Coba lagi.');
        return;
      }

      final embedding = await FaceRecognitionService.instance.extractEmbedding(
        fullImage,
        faces.first,
      );
      if (embedding == null) {
        _showSnack('Wajah tidak terbaca dengan jelas. Coba lagi.');
        return;
      }

      await _finalize(embedding);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Gagal mendaftarkan wajah: ${e.toString()}';
        _step = _EnrollStep.error;
      });
    } finally {
      if (mounted && _step == _EnrollStep.capture) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<void> _finalize(List<double> embedding) async {
    if (!mounted) return;
    setState(() {
      _step = _EnrollStep.processing;
      _capturing = false;
    });

    try {
      final uid = AuthService.instance.currentUserId;
      if (uid == null) throw Exception('Sesi tidak ditemukan');

      await EmbeddingSyncService.instance.saveEmbedding(uid, embedding);

      if (!mounted) return;
      setState(() => _step = _EnrollStep.done);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Gagal menyimpan data wajah: ${e.toString()}';
        _step = _EnrollStep.error;
      });
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _restart() {
    setState(() {
      _step = _EnrollStep.capture;
      _errorMsg = null;
      _capturing = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Daftarkan Wajah',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _EnrollStep.processing:
        return _buildProcessing();
      case _EnrollStep.done:
        return _buildDone();
      case _EnrollStep.error:
        return _buildError();
      default:
        return _buildCaptureStep();
    }
  }

  Widget _buildCaptureStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildInstruction(),
        const SizedBox(height: 12),
        Expanded(child: _buildCameraPreview()),
        const SizedBox(height: 12),
        if (_capturing) _buildSamplingProgress(),
        const SizedBox(height: 8),
        _buildCaptureButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────────

  // ── Instruction card ──────────────────────────────────────────────────────

  Widget _buildInstruction() {
    const title = 'Hadapkan wajah ke kamera';
    const subtitle =
        'Ambil satu foto wajah yang jelas, seperti sistem referensi.';
    const icon = Icons.face_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sampling progress ─────────────────────────────────────────────────────

  Widget _buildSamplingProgress() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Menganalisis wajah...',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Camera preview ────────────────────────────────────────────────────────

  Widget _buildCameraPreview() {
    final ctrl = _camCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: ctrl.value.previewSize!.height,
                height: ctrl.value.previewSize!.width,
                child: CameraPreview(ctrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Capture button ────────────────────────────────────────────────────────

  Widget _buildCaptureButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _capturing ? null : _capture,
          icon: _capturing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.camera_alt_rounded, size: 20),
          label: Text(
            _capturing ? 'Mengambil sampel…' : 'Ambil Foto',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // ── Processing / Done / Error ─────────────────────────────────────────────

  Widget _buildProcessing() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 20),
          Text(
            'Menyimpan data wajah…',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 52,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Wajah Berhasil Didaftarkan!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Data wajah Anda telah disimpan dengan aman.\nAnda sekarang dapat menggunakan absensi wajah.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pendaftaran Gagal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg ?? 'Terjadi kesalahan.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _restart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
