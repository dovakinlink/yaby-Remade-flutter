import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/presentation/pages/announcement_detail_page.dart';
import 'package:yabai_app/features/home/presentation/widgets/feed_card.dart';
import 'package:yabai_app/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:yabai_app/features/home/presentation/widgets/home_header.dart';
import 'package:yabai_app/features/home/presentation/widgets/search_stats_card.dart';
import 'package:yabai_app/features/home/providers/home_announcements_provider.dart';
import 'package:yabai_app/features/home/providers/project_statistics_provider.dart';
import 'package:yabai_app/features/profile/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const routePath = '/home';
  static const routeName = 'home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScrollController _scrollController;
  int _currentTab = 0;
  static const _placeholderValue = '--';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final provider = context.read<HomeAnnouncementsProvider>();
    if (!provider.hasNext || provider.isLoadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      unawaited(provider.loadMore());
    }
  }

  void _onTapTab(int index) {
    if (index == _currentTab) {
      return;
    }
    setState(() => _currentTab = index);

    if (index != 0 && index != 4 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${_tabLabel(index)}"功能即将上线'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _tabLabel(int index) {
    switch (index) {
      case 1:
        return '学习';
      case 2:
        return 'AI';
      case 3:
        return '消息';
      case 4:
        return '我的';
      default:
        return '首页';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final announcementsProvider = context.watch<HomeAnnouncementsProvider>();
    final statsProvider = context.watch<ProjectStatisticsProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: () {
                context.pushNamed('create-post').then((result) {
                  // 如果发布成功，刷新列表
                  if (result == true) {
                    announcementsProvider.refresh();
                  }
                });
              },
              backgroundColor: AppColors.brandGreen,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            )
          : null,
      body: _buildTabStack(
        isDark: isDark,
        announcementsProvider: announcementsProvider,
        statsProvider: statsProvider,
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentTab,
        onTap: _onTapTab,
      ),
    );
  }

  Widget _buildTabStack({
    required bool isDark,
    required HomeAnnouncementsProvider announcementsProvider,
    required ProjectStatisticsProvider statsProvider,
  }) {
    return IndexedStack(
      index: _currentTab,
      children: [
        _buildHomeTab(
          isDark: isDark,
          announcementsProvider: announcementsProvider,
          statsProvider: statsProvider,
        ),
        _buildComingSoonTab(
          title: '学习',
          description: '"学习"功能即将上线',
          icon: Icons.menu_book_rounded,
        ),
        _buildComingSoonTab(
          title: 'AI',
          description: '"AI"功能即将上线',
          icon: Icons.psychology_alt_outlined,
        ),
        _buildComingSoonTab(
          title: '消息',
          description: '"消息"功能即将上线',
          icon: Icons.notifications_none_rounded,
        ),
        const ProfilePage(),
      ],
    );
  }

  Widget _buildHomeTab({
    required bool isDark,
    required HomeAnnouncementsProvider announcementsProvider,
    required ProjectStatisticsProvider statsProvider,
  }) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          final announcements = context.read<HomeAnnouncementsProvider>();
          final statistics = context.read<ProjectStatisticsProvider>();
          await Future.wait([announcements.refresh(), statistics.refresh()]);
        },
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        color: AppColors.brandGreen,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: HomeHeader(
                onOpenDrawer: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('侧边栏导航即将推出')));
                },
                onOpenMessages: () {
                  _onTapTab(3);
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: SearchStatsCard(
                stats: _buildStatsItems(statsProvider),
                onSubmitted: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('搜索 "$value" 功能即将上线'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onTap: () {
                  context.pushNamed('projects');
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ..._buildFeedSlivers(announcementsProvider),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: _buildFooter(announcementsProvider)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonTab({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.brandGreen.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  List<SearchStatItem> _buildStatsItems(ProjectStatisticsProvider provider) {
    final stats = provider.statistics;
    if (stats != null) {
      final isUpdating = provider.isLoading;
      final caption = isUpdating ? '更新中…' : null;
      return [
        SearchStatItem(
          label: '入组中',
          value: '${stats.enrolling}',
          caption: caption,
        ),
        SearchStatItem(label: '待开始', value: '${stats.pending}'),
        SearchStatItem(label: '停止', value: '${stats.stopped}'),
        SearchStatItem(label: '总数', value: '${stats.total}'),
      ];
    }

    final caption = provider.isLoading
        ? '加载中…'
        : provider.errorMessage ?? '暂无统计数据';

    return [
      SearchStatItem(label: '入组中', value: _placeholderValue, caption: caption),
      const SearchStatItem(label: '待开始', value: _placeholderValue),
      const SearchStatItem(label: '停止', value: _placeholderValue),
      const SearchStatItem(label: '总数', value: _placeholderValue),
    ];
  }

  List<Widget> _buildFeedSlivers(HomeAnnouncementsProvider provider) {
    if (provider.isInitialLoading && provider.announcements.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                ),
              ),
            ),
          ),
        ),
      ];
    }

    if (provider.errorMessage != null && provider.announcements.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: _ErrorState(
              message: provider.errorMessage!,
              onRetry: provider.refresh,
            ),
          ),
        ),
      ];
    }

    if (provider.announcements.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: Text('暂无通知公告', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ),
        ),
      ];
    }

    return [
      SliverList.separated(
        itemBuilder: (context, index) {
          final announcement = provider.announcements[index];
          return FeedCard(
            announcement: announcement,
            onTap: () {
              context.pushNamed(
                AnnouncementDetailPage.routeName,
                pathParameters: {'id': '${announcement.id}'},
                extra: announcement,
              );
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemCount: provider.announcements.length,
      ),
    ];
  }

  Widget _buildFooter(HomeAnnouncementsProvider provider) {
    if (provider.announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    if (provider.isLoadingMore) {
      return const SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    if (provider.loadMoreError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.loadMoreError!,
            style: const TextStyle(color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              provider.loadMore();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandGreen,
            ),
            child: const Text('重试加载'),
          ),
        ],
      );
    }

    if (!provider.hasNext) {
      return const Text(
        '已经浏览完全部内容',
        style: TextStyle(color: Color(0xFF94A3B8)),
      );
    }

    return const Text(
      '下拉刷新，继续加载更多内容',
      style: TextStyle(color: Color(0xFF94A3B8)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFEF4444)),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            onRetry();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('重新加载'),
        ),
      ],
    );
  }
}
