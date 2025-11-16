import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/address_book/data/models/address_book_item_model.dart';
import 'package:yabai_app/features/im/data/models/conversation_model.dart';
import 'package:yabai_app/features/im/providers/conversation_list_provider.dart';
import 'package:yabai_app/features/im/presentation/pages/chat_page.dart';
import 'package:yabai_app/features/profile/presentation/pages/user_profile_detail_page.dart';

class AddressBookItemCard extends StatelessWidget {
  const AddressBookItemCard({
    super.key,
    required this.item,
  });

  final AddressBookItemModel item;

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法拨打电话'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 发送私信 - 创建单聊会话
  Future<void> _sendPrivateMessage(BuildContext context, AddressBookItemModel item) async {
    try {
      // 检查是否有userId（联系人类型没有userId，无法发起IM单聊）
      if (item.userId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                item.isFromContact 
                  ? '该联系人没有系统账号，无法发起单聊' 
                  : '无法获取用户ID，无法发起单聊'
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 显示加载提示
      if (!context.mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('正在创建会话...'),
          duration: Duration(seconds: 1),
        ),
      );

      // 创建单聊会话
      final conversationProvider = context.read<ConversationListProvider>();
      final conversation = await conversationProvider.createSingleConversation(item.userId!);

      // 确保 context 仍然有效后再跳转
      if (!context.mounted) {
        debugPrint('Context 已失效，无法跳转到聊天页面');
        return;
      }

      // 跳转到聊天页面
      // 使用 Navigator 而不是 context.pushNamed，确保跳转更可靠
      final router = GoRouter.of(context);
      router.pushNamed(
        ChatPage.routeName,
        pathParameters: {
          'convId': conversation.convId,
        },
        queryParameters: {
          'title': item.name,
        },
      );
    } catch (e) {
      debugPrint('创建会话失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建会话失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showActionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.phone,
                  color: AppColors.brandGreen,
                ),
                title: Text(
                  '拨打电话',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkNeutralText
                        : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  item.phone,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : Colors.grey[600],
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(context, item.phone);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.chat_bubble_outline,
                  color: item.canStartImChat 
                    ? AppColors.brandGreen 
                    : (isDark ? AppColors.darkSecondaryText : Colors.grey),
                ),
                title: Text(
                  '发送私信',
                  style: TextStyle(
                    color: item.canStartImChat
                      ? (isDark ? AppColors.darkNeutralText : Colors.black87)
                      : (isDark ? AppColors.darkSecondaryText : Colors.grey),
                  ),
                ),
                subtitle: Text(
                  item.canStartImChat 
                    ? '发起单聊会话' 
                    : (item.isFromContact ? '该联系人无系统账号' : '无法获取用户ID'),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : Colors.grey[600],
                  ),
                ),
                onTap: item.canStartImChat ? () {
                  Navigator.pop(context);
                  _sendPrivateMessage(context, item);
                } : null, // 不可用时 onTap 为 null
                enabled: item.canStartImChat, // 添加 enabled 属性
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apiClient = context.read<ApiClient>();
    
    // 使用ApiClient解析头像URL并获取认证头
    final resolvedAvatarUrl = item.avatar != null && item.avatar!.isNotEmpty
        ? apiClient.resolveUrlSync(item.avatar!)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 如果有userId，直接跳转到个人详情页
            if (item.userId != null) {
              debugPrint('点击通讯录卡片: ${item.name}, userId: ${item.userId}');
              context.pushNamed(
                UserProfileDetailPage.routeName,
                pathParameters: {'userId': item.userId.toString()},
              );
            } else {
              // 如果没有userId，显示操作菜单（保持原有行为）
              _showActionSheet(context);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // 头像或首字母
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: resolvedAvatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            resolvedAvatarUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            headers: apiClient.getAuthHeaders(),
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  item.nameInitial,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brandGreen,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            item.nameInitial,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandGreen,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkNeutralText
                                    : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.displayRoleName != null && item.displayRoleName!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.displayRoleName!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.brandGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

