// Web stub for CameraFaceView — camera/mlkit not available on web.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../../../shared/theme/app_colors.dart';

enum CameraFaceState { loading, ready, scanning, detected, timeout, error, done }

typedef FaceDetectedCallback = Future<void> Function({
  required img.Image fullImage,
  required dynamic inputImage,
  required Uint8List? nv21Bytes,
  required int rawWidth,
  required int rawHeight,
  required InputImageRotation rotation,
  required dynamic face,
});

class CameraFaceView extends StatefulWidget {
  final bool active;
  final String hint;
  final FaceDetectedCallback? onFaceDetected;
  final VoidCallback? onTimeout;

  const CameraFaceView({
    super.key,
    this.active = true,
    this.hint = 'Arahkan wajah ke kamera',
    this.onFaceDetected,
    this.onTimeout,
  });

  @override
  State<CameraFaceView> createState() => CameraFaceViewState();
}

class CameraFaceViewState extends State<CameraFaceView> {
  void startScan() {}
  void resetToReady() {}
  void markDone() {}
  Future<void> refreshCamera() async {}

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.no_photography_outlined, size: 40, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'Kamera tidak tersedia di browser',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Gunakan aplikasi Android untuk absensi wajah',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
