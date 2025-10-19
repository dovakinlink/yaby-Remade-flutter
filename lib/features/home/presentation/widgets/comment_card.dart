import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/comment_model.dart';
import 'package:yabai_app/features/profile/presentation/pages/user_profile_detail_page.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    required this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 评论人信息
            Row(
              children: [
                _buildAvatar(context, isDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.commenterName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? AppColors.darkNeutralText : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comment.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // 删除按钮（仅自己的评论）
                if (comment.canDelete && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 评论内容
            Text(
              comment.content,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkNeutralText : Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            // 回复按钮
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReply,
                icon: Icon(
                  Icons.reply,
                  size: 16,
                  color: AppColors.brandGreen,
                ),
                label: Text(
                  '回复',
                  style: TextStyle(
                    color: AppColors.brandGreen,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isDark) {
    final apiClient = context.read<ApiClient>();
    final avatarUrl = comment.commenterAvatar;
    
    // 使用ApiClient解析URL
    final resolvedUrl = avatarUrl != null && avatarUrl.isNotEmpty
        ? apiClient.resolveUrlSync(avatarUrl)
        : null;
    
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          UserProfileDetailPage.routeName,
          pathParameters: {'userId': comment.commenterId.toString()},
        );
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.brandGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: resolvedUrl != null
            ? ClipOval(
                child: Image.network(
                  resolvedUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  headers: apiClient.getAuthHeaders(),
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        comment.nameInitial,
                        style: const TextStyle(
                          color: AppColors.brandGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              )
            : Center(
                child: Text(
                  comment.nameInitial,
                  style: const TextStyle(
                    color: AppColors.brandGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}

