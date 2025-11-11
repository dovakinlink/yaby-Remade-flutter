import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/im/providers/conversation_list_provider.dart';
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
        title: const Text('聊天'),
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
              ListTile(
                leading: const Icon(Icons.group_add, color: AppColors.brandGreen),
                title: const Text('创建群聊'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('群聊功能将在后续版本中开放')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

