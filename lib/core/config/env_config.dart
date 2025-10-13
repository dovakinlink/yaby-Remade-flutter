import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class EnvConfig {
  EnvConfig._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static String? _cachedApiBaseUrl;

  static const String simulatorHost = String.fromEnvironment(
    'API_IOS_SIMULATOR_HOST',
    defaultValue: 'http://127.0.0.1:8090',
  );
  static const String androidEmulatorHost = String.fromEnvironment(
    'API_ANDROID_EMULATOR_HOST',
    defaultValue: 'http://10.0.2.2:8090',
  );
  static const String lanHost = String.fromEnvironment(
    'API_LAN_HOST',
    defaultValue: 'http://192.168.0.103:8090',
  );

  static String get initialBaseUrl => simulatorHost;

  static Future<String> resolveApiBaseUrl() async {
    if (_cachedApiBaseUrl != null) {
      return _cachedApiBaseUrl!;
    }

    final baseUrl = await _computeBaseUrl().catchError((_) => lanHost);
    _cachedApiBaseUrl = baseUrl;
    return baseUrl;
  }

  static Future<String> _computeBaseUrl() async {
    if (kIsWeb) {
      return lanHost;
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.isPhysicalDevice ? lanHost : simulatorHost;
    }

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return info.isPhysicalDevice ? lanHost : androidEmulatorHost;
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return simulatorHost;
    }

    return lanHost;
  }
}
