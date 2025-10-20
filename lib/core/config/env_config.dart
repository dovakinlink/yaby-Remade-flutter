import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class EnvConfig {
  EnvConfig._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static String? _cachedApiBaseUrl;

  // 生产环境API地址（通过编译时参数传入）
  static const String productionHost = String.fromEnvironment(
    'API_PRODUCTION_HOST',
    defaultValue: '', // 生产环境地址需要在编译时指定
  );

  // 编译模式标识
  static const String buildMode = String.fromEnvironment(
    'BUILD_MODE',
    defaultValue: 'development',
  );

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
    defaultValue: 'http://192.168.0.101:8090',
  );
  static const String macOSHost = String.fromEnvironment(
    'API_MACOS_HOST',
    defaultValue: 'http://127.0.0.1:8090',
  );

  /// 是否为生产环境
  static bool get isProduction => buildMode == 'production';

  static String get initialBaseUrl => simulatorHost;

  static Future<String> resolveApiBaseUrl() async {
    // 如果是生产环境且配置了生产地址，直接使用
    if (isProduction && productionHost.isNotEmpty) {
      _cachedApiBaseUrl = productionHost;
      debugPrint('使用生产环境API: $productionHost');
      return productionHost;
    }

    // 否则走原有的设备检测逻辑
    if (_cachedApiBaseUrl != null) {
      return _cachedApiBaseUrl!;
    }

    final baseUrl = await _computeBaseUrl().catchError((_) => lanHost);
    _cachedApiBaseUrl = baseUrl;
    debugPrint('使用开发环境API: $baseUrl');
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
