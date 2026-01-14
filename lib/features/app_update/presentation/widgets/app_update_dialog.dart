import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/app_update/data/models/app_update_check_vo.dart';

/// APP 更新对话框
class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  final AppUpdateCheckVO updateInfo;

  /// 显示更新对话框
  static Future<bool?> show(BuildContext context, AppUpdateCheckVO updateInfo) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !updateInfo.force, // 强制更新不可点击外部关闭
      builder: (context) => AppUpdateDialog(updateInfo: updateInfo),
    );
  }

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel('用户取消下载');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      // 强制更新或正在下载时禁止返回
      canPop: !widget.updateInfo.force && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isDark),
              _buildContent(isDark),
              if (_isDownloading)
                _buildDownloadProgress(isDark)
              else
                _buildActions(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandGreen,
            AppColors.brandGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _isDownloading ? Icons.downloading : Icons.system_update,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            _isDownloading ? '正在下载' : '发现新版本',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'v${widget.updateInfo.latestVersionName ?? ""}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          if (widget.updateInfo.fileSize != null && widget.updateInfo.fileSize! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '安装包大小: ${widget.updateInfo.fileSizeFormatted}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final releaseNotes = widget.updateInfo.releaseNotes;
    final hasNotes = releaseNotes != null && releaseNotes.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '更新内容',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkNeutralText : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: hasNotes
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: releaseNotes.map((note) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.brandGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  note,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : Text(
                    '修复已知问题，提升应用稳定性',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
            ),
          ),
          const SizedBox(height: 12),
          // 进度文字
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _downloadStatus,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                ),
              ),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 取消按钮（非强制更新时可取消）
          if (!widget.updateInfo.force)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _cancelDownload,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  '取消下载',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[400],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // 立即更新按钮
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _handleUpdate(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '立即更新',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // 非强制更新时显示"稍后提醒"按钮
          if (!widget.updateInfo.force) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  '稍后提醒',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _cancelDownload() {
    _cancelToken?.cancel('用户取消下载');
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _downloadStatus = '';
    });
  }

  Future<void> _handleUpdate(BuildContext context) async {
    debugPrint('🔄 [AppUpdate] 处理更新点击');
    debugPrint('🔄 [AppUpdate] Platform.isAndroid: ${Platform.isAndroid}');
    debugPrint('🔄 [AppUpdate] downloadUrl: ${widget.updateInfo.downloadUrl}');
    debugPrint('🔄 [AppUpdate] storeUrl: ${widget.updateInfo.storeUrl}');

    // Android 平台使用下载安装方式
    if (Platform.isAndroid && 
        widget.updateInfo.downloadUrl != null && 
        widget.updateInfo.downloadUrl!.isNotEmpty) {
      await _downloadAndInstallApk(context, widget.updateInfo.downloadUrl!);
      return;
    }

    // iOS 或其他平台使用应用商店链接
    if (widget.updateInfo.storeUrl != null && widget.updateInfo.storeUrl!.isNotEmpty) {
      await _openStoreUrl(context, widget.updateInfo.storeUrl!);
      return;
    }

    // 无可用链接
    debugPrint('❌ [AppUpdate] 无可用的更新链接');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法获取更新链接'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 下载并安装 APK (Android)
  Future<void> _downloadAndInstallApk(BuildContext context, String downloadUrl) async {
    debugPrint('📥 [AppUpdate] 开始下载 APK: $downloadUrl');

    // 请求安装权限 (Android 8.0+)
    if (Platform.isAndroid) {
      final installPermission = await Permission.requestInstallPackages.status;
      debugPrint('📥 [AppUpdate] 安装权限状态: $installPermission');
      
      if (!installPermission.isGranted) {
        final result = await Permission.requestInstallPackages.request();
        debugPrint('📥 [AppUpdate] 请求安装权限结果: $result');
        
        if (!result.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('需要安装权限才能更新应用'),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: '去设置',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = '准备下载...';
    });

    try {
      // 获取下载目录
      final Directory cacheDir = await getTemporaryDirectory();
      final String fileName = 'app_update_${widget.updateInfo.latestVersionName ?? 'latest'}.apk';
      final String savePath = '${cacheDir.path}/$fileName';
      
      debugPrint('📥 [AppUpdate] 保存路径: $savePath');

      // 如果文件已存在，先删除
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('📥 [AppUpdate] 已删除旧文件');
      }

      // 创建 CancelToken
      _cancelToken = CancelToken();

      // 创建 Dio 实例下载
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(minutes: 10);

      setState(() {
        _downloadStatus = '正在下载...';
      });

      await dio.download(
        downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            setState(() {
              _downloadProgress = progress;
              _downloadStatus = '正在下载... ${_formatBytes(received)} / ${_formatBytes(total)}';
            });
          }
        },
      );

      debugPrint('📥 [AppUpdate] 下载完成: $savePath');

      // 检查文件是否存在
      if (!await file.exists()) {
        throw Exception('下载文件不存在');
      }

      final fileSize = await file.length();
      debugPrint('📥 [AppUpdate] 文件大小: $fileSize bytes');

      setState(() {
        _downloadStatus = '下载完成，正在安装...';
        _downloadProgress = 1.0;
      });

      // 延迟一下让用户看到完成状态
      await Future.delayed(const Duration(milliseconds: 500));

      // 打开 APK 文件进行安装
      debugPrint('📥 [AppUpdate] 正在打开安装器...');
      final result = await OpenFilex.open(savePath);
      debugPrint('📥 [AppUpdate] OpenFilex 结果: type=${result.type}, message=${result.message}');

      if (result.type != ResultType.done) {
        throw Exception('无法打开安装器: ${result.message}');
      }

      // 安装器已打开，关闭对话框
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }

    } on DioException catch (e) {
      debugPrint('❌ [AppUpdate] 下载失败: ${e.type} - ${e.message}');
      
      if (e.type == DioExceptionType.cancel) {
        debugPrint('📥 [AppUpdate] 下载已取消');
        return;
      }

      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
        _downloadStatus = '';
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: ${e.message ?? '网络错误'}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AppUpdate] 更新失败: $e');
      debugPrint('❌ [AppUpdate] 堆栈: $stackTrace');

      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
        _downloadStatus = '';
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// 打开应用商店链接 (iOS 或备用方案)
  Future<void> _openStoreUrl(BuildContext context, String storeUrl) async {
    debugPrint('🔄 [AppUpdate] 打开应用商店: $storeUrl');
    
    try {
      final uri = Uri.parse(storeUrl);
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('无法打开链接');
      }
    } catch (e) {
      debugPrint('❌ [AppUpdate] 打开商店链接失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法打开应用商店: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
