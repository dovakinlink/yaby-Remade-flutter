import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/mock_feed.dart';
import 'package:yabai_app/features/home/presentation/widgets/feed_card.dart';
import 'package:yabai_app/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:yabai_app/features/home/presentation/widgets/home_header.dart';
import 'package:yabai_app/features/home/presentation/widgets/search_stats_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const routePath = '/home';
  static const routeName = 'home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScrollController _scrollController;
  final List<MockFeed> _feeds = List.of(MockFeed.sampleFeed());
  final ValueNotifier<bool> _isRefreshing = ValueNotifier<bool>(false);

  bool _isLoadingMore = false;
  int _currentPage = 0;
  int _currentTab = 0;

  // 固定的统计数据，符合设计图
  List<SearchStatItem> get _stats => const [
    SearchStatItem(label: '入组中', value: '124'),
    SearchStatItem(label: '待开始', value: '3'),
    SearchStatItem(label: '停止', value: '87'),
    SearchStatItem(label: '总数', value: '214'),
  ];

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
    _isRefreshing.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_isLoadingMore) {
      return;
    }
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) {
      return;
    }
    setState(() {
      _isLoadingMore = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final nextPage = _currentPage + 1;
    final newItems = MockFeed.sampleFeed(page: nextPage);
    if (!mounted) {
      return;
    }
    setState(() {
      _currentPage = nextPage;
      _feeds.addAll(newItems);
      _isLoadingMore = false;
    });
  }

  Future<void> _onRefresh() async {
    _isRefreshing.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) {
      return;
    }
    setState(() {
      _currentPage = 0;
      _feeds
        ..clear()
        ..addAll(MockFeed.sampleFeed());
    });
    _isRefreshing.value = false;
  }

  void _onTapTab(int index) {
    if (index == _currentTab) {
      return;
    }
    setState(() {
      _currentTab = index;
    });
    if (index != 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('“${_tabLabel(index)}”功能即将上线'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _tabLabel(int index) {
    switch (index) {
      case 1:
        return '探索';
      case 2:
        return '工作台';
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
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffoldBackground : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
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
                  stats: _stats,
                  onSubmitted: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('搜索 "$value" 功能即将上线'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverList.separated(
                itemBuilder: (context, index) {
                  final feed = _feeds[index];
                  return FeedCard(feed: feed);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemCount: _feeds.length,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.brandGreen,
                              ),
                            ),
                          )
                        : ValueListenableBuilder<bool>(
                            valueListenable: _isRefreshing,
                            builder: (context, value, child) {
                              if (value) {
                                return const SizedBox.shrink();
                              }
                              return const Text(
                                '下拉刷新，继续加载更多内容',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentTab,
        onTap: _onTapTab,
      ),
    );
  }
}
