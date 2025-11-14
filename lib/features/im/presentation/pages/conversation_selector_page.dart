import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/im/providers/conversation_list_provider.dart';
import 'package:yabai_app/features/im/providers/chat_provider.dart';
import 'package:yabai_app/features/im/data/repositories/im_repository.dart';
import 'package:yabai_app/features/im/providers/websocket_provider.dart';
import 'package:yabai_app/features/auth/providers/user_profile_provider.dart';
import 'package:yabai_app/features/im/presentation/pages/chat_page.dart';

/// 会话选择器页面（用于分享内容到聊天）
class ConversationSelectorPage extends StatefulWidget {
  final Map<String, dynamic> shareData;
  final String shareType;

  const ConversationSelectorPage({
    super.key,
    required this.shareData,
    required this.shareType,
  });

  static const routePath = '/select-conversation';
  static const routeName = 'select-conversation';

  @override
  State<ConversationSelectorPage> createState() => _ConversationSelectorPageState();
}

class _ConversationSelectorPageState extends State<ConversationSelectorPage> {
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // 加载会话列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationListProvider>().loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('选择聊天'),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
      ),
      body: Consumer<ConversationListProvider>(
        builder: (context, provider, child) {
          if (provider.isInitialLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
              ),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (provider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: isDark ? AppColors.darkSecondaryText : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无会话',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.darkSecondaryText : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = provider.conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.brandGreen.withValues(alpha: 0.1),
                  child: Icon(
                    conversation.type.value == 'GROUP'
                        ? Icons.group
                        : Icons.person,
                    color: AppColors.brandGreen,
                  ),
                ),
                title: Text(
                  conversation.title ?? '未命名会话',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkNeutralText
                        : AppColors.lightNeutralText,
                  ),
                ),
                subtitle: Text(
                  conversation.type.value == 'GROUP' ? '群聊' : '单聊',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : Colors.grey[600],
                  ),
                ),
                onTap: _isSending
                    ? null
                    : () => _handleSelectConversation(conversation.convId),
              );
            },
          );
        },
      ),
    );
  }

  /// 处理选择会话
  Future<void> _handleSelectConversation(String convId) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // 获取当前用户信息
      final userProfile = context.read<UserProfileProvider>();
      final currentUserId = userProfile.profile?.id ?? 0;
      final currentUserAvatar = userProfile.profile?.avatar;
      final currentUserName = userProfile.profile?.displayName;

      // 创建 ChatProvider 并发送消息
      final chatProvider = ChatProvider(
        repository: context.read<ImRepository>(),
        websocketProvider: context.read<WebSocketProvider>(),
        convId: convId,
        currentUserId: currentUserId,
        currentUserAvatar: currentUserAvatar,
        currentUserName: currentUserName,
      );

      // 根据分享类型发送不同的消息
      if (widget.shareType == 'PROJECT_CARD') {
        await chatProvider.sendProjectCardMessage(widget.shareData);
      }

      if (!mounted) return;

      // 跳转到聊天页面
      context.go('/home'); // 先回到首页
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      context.pushNamed(
        ChatPage.routeName,
        pathParameters: {'convId': convId},
      );

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('分享成功'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分享失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}

