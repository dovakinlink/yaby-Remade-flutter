import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/im/data/models/conversation_model.dart';
import 'package:yabai_app/features/im/providers/conversation_list_provider.dart';
import 'package:yabai_app/features/im/providers/websocket_provider.dart';
import 'package:yabai_app/features/im/presentation/widgets/conversation_list_item.dart';
import 'package:yabai_app/features/im/presentation/pages/chat_page.dart';

/// 会话列表页面
class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});

  static const routePath = 'im';
  static const routeName = 'im';

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时自动加载会话列表
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
        automaticallyImplyLeading: false,
        title: Consumer<WebSocketProvider>(
          builder: (context, websocketProvider, child) {
            return _buildConnectionStatus(websocketProvider, isDark);
          },
        ),
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // TODO: 显示创建单聊/群聊菜单
              _showCreateMenu(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ConversationListProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: provider.refresh,
              backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
              color: AppColors.brandGreen,
              child: _buildBody(provider, isDark),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(ConversationListProvider provider, bool isDark) {
    // 初始加载中
    if (provider.isInitialLoading && provider.conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    // 加载失败且列表为空
    if (provider.errorMessage != null && provider.conversations.isEmpty) {
      return _buildErrorState(provider);
    }

    // 列表为空
    if (provider.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无聊天',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showCreateMenu(context),
              child: const Text('发起聊天'),
            ),
          ],
        ),
      );
    }

    // 显示会话列表
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: provider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = provider.conversations[index];
        return ConversationListItem(
          conversation: conversation,
          onTap: () {
            // 导航到聊天页面
            context.pushNamed(
              ChatPage.routeName,
              pathParameters: {'convId': conversation.convId},
              queryParameters: {'title': conversation.title ?? '聊天'},
            );
          },
          onLongPress: () {
            // 长按显示删除确认对话框
            _showDeleteConfirmDialog(context, provider, conversation);
          },
        );
      },
    );
  }

  Widget _buildErrorState(ConversationListProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadInitial(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add, color: AppColors.brandGreen),
                title: const Text('发起单聊'),
                subtitle: const Text('从通讯录选择联系人'),
                onTap: () {
                  Navigator.pop(context);
                  // 跳转到通讯录页面
                  context.pushNamed('address-book');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(
    BuildContext context,
    ConversationListProvider provider,
    Conversation conversation,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversationTitle = conversation.title ?? '未命名会话';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        title: Text(
          '删除会话',
          style: TextStyle(
            color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
          ),
        ),
        content: Text(
          '确定要删除与"$conversationTitle"的会话吗？\n\n删除后，你和对方的聊天记录均将被清除，且无法恢复。',
          style: TextStyle(
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '取消',
              style: TextStyle(
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _handleDeleteConversation(context, provider, conversation);
            },
            child: const Text(
              '删除',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理删除会话
  Future<void> _handleDeleteConversation(
    BuildContext context,
    ConversationListProvider provider,
    Conversation conversation,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // 显示加载提示
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('正在删除...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await provider.deleteConversation(conversation.convId);
      
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('删除成功'),
            backgroundColor: AppColors.brandGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('删除失败: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 构建连接状态指示器
  Widget _buildConnectionStatus(WebSocketProvider websocketProvider, bool isDark) {
    if (websocketProvider.isConnected) {
      // 已连接：显示app主色调颜色的"在线"两字
      return Text(
        '在线',
        style: TextStyle(
          color: AppColors.brandGreen,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (websocketProvider.isConnecting || websocketProvider.isReconnecting) {
      // 连接中/重连中：显示旋转的加载图标
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? AppColors.darkSecondaryText : Colors.grey[600]!,
          ),
        ),
      );
    } else {
      // 未连接：显示灰色圆点
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSecondaryText : Colors.grey[400]!,
          shape: BoxShape.circle,
        ),
      );
    }
  }
}

