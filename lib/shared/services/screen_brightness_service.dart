import 'package:screen_brightness/screen_brightness.dart';

/// Paksa kecerahan layar ke maksimum saat kamera aktif,
/// lalu kembalikan saat semua view kamera sudah selesai.
class ScreenBrightnessService {
  static final ScreenBrightnessService instance = ScreenBrightnessService._();
  ScreenBrightnessService._();

  int _activeLocks = 0;

  Future<void> acquireMax() async {
    _activeLocks += 1;
    if (_activeLocks > 1) return;
    await setMax();
  }

  Future<void> releaseMax() async {
    if (_activeLocks == 0) return;
    _activeLocks -= 1;
    if (_activeLocks > 0) return;
    await restore();
  }

  Future<void> setMax() async {
    try {
      await ScreenBrightness.instance.setScreenBrightness(1.0);
    } catch (_) {
      // Device tidak mendukung - abaikan.
    }
  }

  Future<void> restore() async {
    try {
      await ScreenBrightness.instance.resetScreenBrightness();
    } catch (_) {}
  }
}
