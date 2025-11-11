import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

/// 聊天输入栏组件
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSendText;
  final VoidCallback? onSendImage;
  final VoidCallback? onSendFile;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSendText,
    this.onSendImage,
    this.onSendFile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 附件按钮
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: isDark ? AppColors.darkNeutralText : Colors.grey[700],
              onPressed: () => _showAttachmentMenu(context),
            ),
            // 输入框
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkFieldBackground
                      : AppColors.lightFieldBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    onSendText(text.trim());
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // 发送按钮
            GestureDetector(
              onTap: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  onSendText(text);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: AppColors.brandGreen),
                title: const Text('发送图片'),
                onTap: () {
                  Navigator.pop(context);
                  onSendImage?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: AppColors.brandGreen),
                title: const Text('发送文件'),
                onTap: () {
                  Navigator.pop(context);
                  onSendFile?.call();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

