import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceBindingInfo {
  final String id;
  final String name;
  final String platform;

  const DeviceBindingInfo({
    required this.id,
    required this.name,
    required this.platform,
  });
}

class DeviceBindingService {
  static final DeviceBindingService instance = DeviceBindingService._();
  DeviceBindingService._();

  static const _deviceIdKey = 'presensia_device_binding_id';
  static const _uuid = Uuid();

  Future<DeviceBindingInfo> getDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    final platform = _platformName();
    return DeviceBindingInfo(
      id: deviceId,
      name: 'Presensia $platform',
      platform: platform.toLowerCase(),
    );
  }

  String _platformName() {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }
}
