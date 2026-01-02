import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/app_update/data/models/app_update_check_vo.dart';

/// APP 更新对话框
class AppUpdateDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      // 强制更新时禁止返回
      canPop: !updateInfo.force,
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
          const Icon(
            Icons.system_update,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            '发现新版本',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'v${updateInfo.latestVersionName ?? ""}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          if (updateInfo.fileSize != null && updateInfo.fileSize! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '安装包大小: ${updateInfo.fileSizeFormatted}',
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
    final releaseNotes = updateInfo.releaseNotes;
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
          if (!updateInfo.force) ...[
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

  Future<void> _handleUpdate(BuildContext context) async {
    String? urlToOpen;

    // Android 优先使用直接下载链接
    if (Platform.isAndroid && 
        updateInfo.downloadUrl != null && 
        updateInfo.downloadUrl!.isNotEmpty) {
      urlToOpen = updateInfo.downloadUrl;
    } else if (updateInfo.storeUrl != null && updateInfo.storeUrl!.isNotEmpty) {
      urlToOpen = updateInfo.storeUrl;
    }

    if (urlToOpen == null || urlToOpen.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法获取更新链接'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(urlToOpen);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法打开更新链接'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开链接失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
