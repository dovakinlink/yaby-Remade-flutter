import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/features/app_update/data/models/app_update_check_vo.dart';

/// APP 更新检测服务
class AppUpdateService {
  AppUpdateService(this._apiClient);

  final ApiClient _apiClient;

  /// 检测应用更新
  /// 
  /// 返回 [AppUpdateCheckVO] 表示更新信息，返回 null 表示检测失败或无更新
  Future<AppUpdateCheckVO?> checkUpdate() async {
    try {
      // 获取应用信息
      final packageInfo = await PackageInfo.fromPlatform();
      final versionName = packageInfo.version;
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      // 获取设备 ID
      final deviceId = await _getDeviceId();

      // 确定平台和渠道
      final platform = Platform.isIOS ? 'ios' : 'android';
      final channelCode = Platform.isIOS ? 'appstore' : 'official';

      debugPrint('📦 [AppUpdate] 检测更新...');
      debugPrint('📦 [AppUpdate] 版本: $versionName ($buildNumber)');
      debugPrint('📦 [AppUpdate] 平台: $platform, 渠道: $channelCode');
      debugPrint('📦 [AppUpdate] 设备ID: $deviceId');

      final response = await _apiClient.post(
        '/api/app/update/check',
        data: {
          'appKey': 'yaby_app',
          'platform': platform,
          'channelCode': channelCode,
          'versionName': versionName,
          'buildNumber': buildNumber,
          'deviceId': deviceId,
        },
      );

      final data = response.data;
      if (data == null) {
        debugPrint('📦 [AppUpdate] 响应为空');
        return null;
      }

      debugPrint('📦 [AppUpdate] 响应数据: $data');

      // 处理 code 可能是数字或字符串的情况
      final codeValue = data['code'];
      final code = codeValue is int 
          ? codeValue 
          : (codeValue is String ? int.tryParse(codeValue) : null);
      
      debugPrint('📦 [AppUpdate] 响应 code: $code (类型: ${codeValue.runtimeType})');

      // code 为 0 或 null 都视为成功（有些 API 可能不返回 code）
      if (code != null && code != 0) {
        final message = data['message'] ?? '未知错误';
        debugPrint('📦 [AppUpdate] 响应错误: code=$code, message=$message');
        // 静默返回 null，不在界面显示错误
        return null;
      }

      final resultData = data['data'];
      if (resultData == null) {
        debugPrint('📦 [AppUpdate] data 字段为空');
        return null;
      }

      debugPrint('📦 [AppUpdate] data 内容: $resultData');

      final result = AppUpdateCheckVO.fromJson(resultData as Map<String, dynamic>);
      debugPrint('📦 [AppUpdate] 解析结果: hasUpdate=${result.hasUpdate}, force=${result.force}');
      
      if (result.hasUpdate) {
        debugPrint('📦 [AppUpdate] 检测到更新: ${result.latestVersionName} (${result.latestBuildNumber})');
      } else {
        debugPrint('📦 [AppUpdate] 当前已是最新版本');
      }

      return result;
    } on DioException catch (e) {
      // 输出控制台日志，但不显示界面错误
      debugPrint('📦 [AppUpdate] 网络错误: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('📦 [AppUpdate] 响应状态码: ${e.response?.statusCode}');
        debugPrint('📦 [AppUpdate] 响应数据: ${e.response?.data}');
      }
      // 静默返回 null，不在界面显示错误
      return null;
    } catch (e, stackTrace) {
      // 输出控制台日志，但不显示界面错误
      debugPrint('📦 [AppUpdate] 检测失败: $e');
      debugPrint('📦 [AppUpdate] 堆栈: $stackTrace');
      // 静默返回 null，不在界面显示错误
      return null;
    }
  }

  /// 获取设备唯一标识
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown-ios';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      }

      return 'unknown-device';
    } catch (e) {
      debugPrint('📦 [AppUpdate] 获取设备ID失败: $e');
      return 'unknown-device';
    }
  }
}
