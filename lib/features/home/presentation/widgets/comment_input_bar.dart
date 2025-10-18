import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/comment_model.dart';

class CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Comment? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  const CommentInputBar({
    super.key,
    required this.controller,
    this.replyingTo,
    required this.onCancelReply,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 回复提示
            if (replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.brandGreen.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '回复 ${replyingTo!.commenterName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onCancelReply,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: AppColors.brandGreen,
                    ),
                  ],
                ),
              ),

            // 输入框
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: replyingTo != null
                            ? '回复 ${replyingTo!.commenterName}'
                            : '写评论...',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.darkSecondaryText : Colors.grey[500],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: AppColors.brandGreen,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                      ),
                      style: TextStyle(
                        color: isDark ? AppColors.darkNeutralText : Colors.black87,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSubmit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                            ),
                          )
                        : Icon(
                            Icons.send,
                            color: AppColors.brandGreen,
                          ),
                    tooltip: '发送',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

