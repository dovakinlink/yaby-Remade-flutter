/// APP 更新检测响应模型
class AppUpdateCheckVO {
  final bool hasUpdate;
  final bool force;
  final String? latestVersionName;
  final int? latestBuildNumber;
  final String? minSupportedVersionName;
  final int? minSupportedBuildNumber;
  final String? storeUrl;
  final String? downloadUrl;
  final String? fileSha256;
  final int? fileSize;
  final List<String>? releaseNotes;

  const AppUpdateCheckVO({
    required this.hasUpdate,
    required this.force,
    this.latestVersionName,
    this.latestBuildNumber,
    this.minSupportedVersionName,
    this.minSupportedBuildNumber,
    this.storeUrl,
    this.downloadUrl,
    this.fileSha256,
    this.fileSize,
    this.releaseNotes,
  });

  factory AppUpdateCheckVO.fromJson(Map<String, dynamic> json) {
    // 处理布尔值可能是字符串的情况
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      if (value is int) return value != 0;
      return false;
    }

    return AppUpdateCheckVO(
      hasUpdate: parseBool(json['hasUpdate']),
      force: parseBool(json['force']),
      latestVersionName: json['latestVersionName'] as String?,
      latestBuildNumber: json['latestBuildNumber'] as int?,
      minSupportedVersionName: json['minSupportedVersionName'] as String?,
      minSupportedBuildNumber: json['minSupportedBuildNumber'] as int?,
      storeUrl: json['storeUrl'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      fileSha256: json['fileSha256'] as String?,
      fileSize: json['fileSize'] as int?,
      releaseNotes: (json['releaseNotes'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasUpdate': hasUpdate,
      'force': force,
      'latestVersionName': latestVersionName,
      'latestBuildNumber': latestBuildNumber,
      'minSupportedVersionName': minSupportedVersionName,
      'minSupportedBuildNumber': minSupportedBuildNumber,
      'storeUrl': storeUrl,
      'downloadUrl': downloadUrl,
      'fileSha256': fileSha256,
      'fileSize': fileSize,
      'releaseNotes': releaseNotes,
    };
  }

  /// 获取文件大小的可读格式
  String get fileSizeFormatted {
    if (fileSize == null) return '';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = fileSize!.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  @override
  String toString() {
    return 'AppUpdateCheckVO(hasUpdate: $hasUpdate, force: $force, '
        'latestVersionName: $latestVersionName, latestBuildNumber: $latestBuildNumber)';
  }
}
