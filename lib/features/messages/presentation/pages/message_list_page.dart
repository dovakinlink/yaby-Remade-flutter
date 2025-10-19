import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/messages/data/models/message_model.dart';
import 'package:yabai_app/features/messages/presentation/pages/message_detail_page.dart';
import 'package:yabai_app/features/messages/presentation/widgets/message_empty_state.dart';
import 'package:yabai_app/features/messages/presentation/widgets/message_list_item.dart';
import 'package:yabai_app/features/messages/providers/message_list_provider.dart';
import 'package:yabai_app/features/messages/providers/message_unread_count_provider.dart';

/// 消息列表页面
class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key});

  static const routePath = 'messages';
  static const routeName = 'messages';

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    
    // 页面加载时自动刷新数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MessageListProvider>();
      provider.loadInitial();
      
      // 同时刷新未读消息数量
      final countProvider = context.read<MessageUnreadCountProvider>();
      countProvider.refresh();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final provider = context.read<MessageListProvider>();
    if (!provider.hasNext || provider.isLoadingMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      unawaited(provider.loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
          ? AppColors.darkScaffoldBackground 
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text('消息中心'),
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Consumer<MessageListProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () async {
                await provider.refresh();
                // 刷新未读消息数量
                if (mounted) {
                  await context.read<MessageUnreadCountProvider>().refresh();
                }
              },
              backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
              color: AppColors.brandGreen,
              child: _buildBody(provider, isDark),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(MessageListProvider provider, bool isDark) {
    // 初始加载中
    if (provider.isInitialLoading && provider.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    // 加载失败且列表为空
    if (provider.errorMessage != null && provider.isEmpty) {
      return _buildErrorState(provider);
    }

    // 列表为空
    if (provider.isEmpty) {
      return MessageEmptyState(
        onRefresh: () => provider.refresh(),
      );
    }

    // 显示消息列表
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: provider.messages.length + (provider.hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        // 加载更多指示器
        if (index == provider.messages.length) {
          return _buildLoadMoreIndicator(provider);
        }

        final message = provider.messages[index];
        return MessageListItem(
          message: message,
          onTap: () => _navigateToMessageDetail(message),
        );
      },
    );
  }

  Widget _buildErrorState(MessageListProvider provider) {
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
              onPressed: () => provider.refresh(),
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

  Widget _buildLoadMoreIndicator(MessageListProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
            ),
          ),
        ),
      );
    }

    if (provider.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Text(
                provider.loadMoreError!,
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => provider.loadMore(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandGreen,
                ),
                child: const Text('重试加载'),
              ),
            ],
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          '已经浏览完全部内容',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  void _navigateToMessageDetail(Message message) {
    context.pushNamed(
      MessageDetailPage.routeName,
      pathParameters: {'id': '${message.id}'},
      extra: message,
    ).then((_) {
      // 从详情页面返回后，刷新消息列表和未读数量
      if (mounted) {
        context.read<MessageListProvider>().refresh();
        context.read<MessageUnreadCountProvider>().refresh();
      }
    });
  }
}
