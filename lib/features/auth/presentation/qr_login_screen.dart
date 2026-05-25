import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/services/qr_login_service.dart';
import '../../../shared/theme/app_colors.dart';

class QrLoginScreen extends StatefulWidget {
  const QrLoginScreen({super.key});

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    String? value;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        value = raw;
        break;
      }
    }
    if (value == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _scanner.stop();
      await QrLoginService.instance.loginWithQrPayload(value);
      if (mounted) Navigator.pop(context, true);
    } on QrLoginException catch (e) {
      await _showScanError(e.message);
    } catch (_) {
      await _showScanError('Tidak dapat memproses QR Login. Coba lagi.');
    }
  }

  Future<void> _showScanError(String message) async {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _errorMessage = message;
    });
    await _scanner.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(controller: _scanner, onDetect: _handleDetect),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            _buildHeader(),
            Center(child: _buildFrame()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Row(
        children: [
          IconButton.filled(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scan QR Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Khusus karyawan dari dashboard admin',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () => _scanner.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrame() {
    return Container(
      width: 268,
      height: 268,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: _isProcessing
          ? Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildFooter() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 26,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _errorMessage == null
            ? const Text(
                'QR karyawan hanya berlaku sekali. Setelah berhasil, akun akan terikat ke perangkat ini.',
                key: ValueKey('hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Container(
                key: const ValueKey('error'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}
