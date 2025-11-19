import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/config/env_config.dart';
import 'package:yabai_app/features/home/presentation/pages/announcement_detail_page.dart';
import 'package:yabai_app/features/home/presentation/widgets/feed_card.dart';
import 'package:yabai_app/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:yabai_app/features/home/presentation/widgets/home_header.dart';
import 'package:yabai_app/features/home/presentation/widgets/search_stats_card.dart';
import 'package:yabai_app/features/home/presentation/widgets/notice_tag_filter.dart';
import 'package:yabai_app/features/home/providers/home_announcements_provider.dart';
import 'package:yabai_app/features/home/providers/project_statistics_provider.dart';
import 'package:yabai_app/features/profile/presentation/pages/profile_page.dart';
import 'package:yabai_app/features/messages/presentation/pages/message_list_page.dart';
import 'package:yabai_app/features/screening/data/repositories/screening_repository.dart';
import 'package:yabai_app/features/screening/providers/screening_list_provider.dart';
import 'package:yabai_app/features/screening/presentation/pages/screening_list_page.dart';
import 'package:yabai_app/features/ai/presentation/pages/ai_entry_page.dart';
import 'package:yabai_app/features/im/presentation/pages/conversation_list_page.dart';
import 'package:yabai_app/features/im/providers/websocket_provider.dart';
import 'package:yabai_app/features/im/providers/unread_count_provider.dart';
import 'package:yabai_app/features/im/providers/conversation_list_provider.dart';
import 'package:yabai_app/features/auth/providers/auth_session_provider.dart';
import 'package:yabai_app/features/auth/providers/user_profile_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const routePath = '/home';
  static const routeName = 'home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final ScrollController _scrollController;
  int _currentTab = 0;
  static const _placeholderValue = '--';
  Timer? _unreadCountTimer; // IM未读消息定时器

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController()..addListener(_handleScroll);
    
    // 加载标签列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeAnnouncementsProvider>().loadAnnouncementTags();
      // 检查并连接 WebSocket
      _ensureWebSocketConnection();
      // 加载IM未读消息总数
      _loadUnreadCount();
      // 启动定时器，每1分钟更新一次未读消息总数
      _startUnreadCountTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App恢复前台时，检查并重连WebSocket，刷新会话列表
      debugPrint('App恢复前台，检查WebSocket连接...');
      _handleAppResumed();
    }
  }

  /// 处理App恢复前台
  Future<void> _handleAppResumed() async {
    try {
      final websocketProvider = context.read<WebSocketProvider>();
      final authSession = context.read<AuthSessionProvider>();
      
      if (!authSession.isAuthenticated) {
        return;
      }

      // 如果WebSocket未连接，尝试重连
      if (!websocketProvider.isConnected && !websocketProvider.isConnecting) {
        debugPrint('WebSocket未连接，尝试重连...');
        await _ensureWebSocketConnection();
      }

      // 刷新会话列表（会从服务器拉取最新数据，包括离线期间的消息）
      if (_currentTab == 1) {
        // 如果当前在聊天tab，刷新会话列表
        final conversationListProvider = context.read<ConversationListProvider>();
        await conversationListProvider.refresh();
      }

      // 刷新未读消息总数
      _loadUnreadCount();
    } catch (e) {
      debugPrint('App恢复时处理失败: $e');
    }
  }

  /// 确保 WebSocket 已连接
  Future<void> _ensureWebSocketConnection() async {
    try {
      final websocketProvider = context.read<WebSocketProvider>();
      final authSession = context.read<AuthSessionProvider>();
      
      // 如果未登录或已连接，则不处理
      if (!authSession.isAuthenticated || websocketProvider.isConnected || websocketProvider.isConnecting) {
        return;
      }
      
      final tokens = authSession.tokens;
      if (tokens == null) {
        return;
      }
      
      final baseUrl = await EnvConfig.resolveApiBaseUrl();
      final uri = Uri.parse(baseUrl);
      final host = uri.host;
      final port = uri.port;
      
      debugPrint('WebSocket: 首页自动连接 - host: $host, port: $port');
      
      websocketProvider.connect(host, port, tokens.accessToken).catchError((e) {
        debugPrint('WebSocket: 自动连接失败 - $e');
      });
    } catch (e) {
      debugPrint('WebSocket: 检查连接失败 - $e');
    }
  }

  /// 加载IM未读消息总数
  void _loadUnreadCount() {
    if (mounted) {
      context.read<UnreadCountProvider>().loadUnreadCount();
    }
  }

  /// 启动IM未读消息定时器（每1分钟更新一次）
  void _startUnreadCountTimer() {
    _unreadCountTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadUnreadCount();
    });
  }

  /// 停止IM未读消息定时器
  void _stopUnreadCountTimer() {
    _unreadCountTimer?.cancel();
    _unreadCountTimer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _stopUnreadCountTimer(); // 停止IM未读消息定时器
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
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      body: _buildTabStack(
        isDark: isDark,
        announcementsProvider: announcementsProvider,
        statsProvider: statsProvider,
      ),
      bottomNavigationBar: Consumer<UnreadCountProvider>(
        builder: (context, unreadCountProvider, child) {
          return HomeBottomNav(
            currentIndex: _currentTab,
            onTap: _onTapTab,
            unreadCount: unreadCountProvider.unreadCount,
          );
        },
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
        _buildImTab(),
        _buildAiTab(),
        _buildScreeningTab(),
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
          final unreadCount = context.read<UnreadCountProvider>();
          await Future.wait([
            announcements.refresh(),
            statistics.refresh(),
            unreadCount.loadUnreadCount(), // 刷新IM未读消息总数
          ]);
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
                onOpenMessages: () {
                  context.goNamed(MessageListPage.routeName);
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
            SliverToBoxAdapter(
              child: _buildQuickActionsRow(isDark),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ..._buildTagFilterSlivers(announcementsProvider),
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

  Widget _buildImTab() {
    // IM 会话列表页面
    return const ConversationListPage();
  }

  Widget _buildAiTab() {
    return const AiEntryPage();
  }

  Widget _buildScreeningTab() {
    return ChangeNotifierProvider(
      create: (context) =>
          ScreeningListProvider(context.read<ScreeningRepository>())
            ..loadInitial(),
      child: const ScreeningListPage(),
    );
  }

  void _handleQuickActionTap(String label) {
    switch (label) {
      case '通讯录':
        context.pushNamed('address-book');
        break;
      case '用药预约':
        context.pushNamed('med-appt');
        break;
      case '学习中心':
        context.pushNamed('learning'); // 学习资源列表页面
        break;
      case '我的项目':
        final userProfile = context.read<UserProfileProvider>().profile;
        if (userProfile?.personId != null && userProfile!.personId!.isNotEmpty) {
          context.pushNamed('my-projects');
        } else {
          // 如果没有 personId，尝试重新加载用户信息
          context.read<UserProfileProvider>().loadProfile().then((_) {
            final updatedProfile = context.read<UserProfileProvider>().profile;
            if (updatedProfile?.personId != null && updatedProfile!.personId!.isNotEmpty) {
              if (context.mounted) {
                context.pushNamed('my-projects');
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('无法获取用户信息，请稍后重试'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          });
        }
        break;
    }
  }

  Widget _buildQuickActionsRow(bool isDark) {
    const actions = <Map<String, dynamic>>[
      {
        'label': '通讯录',
        'asset': 'assets/images/Call.svg',
        'isSvg': true,
      },
      {
        'label': '用药预约',
        'asset': 'assets/icons/Calendar.svg',
        'isSvg': true,
      },
      {
        'label': '我的项目',
        'asset': 'assets/images/Folder.svg',
        'isSvg': true,
      },
      {
        'label': '学习中心',
        'asset': 'assets/images/Image.svg',
        'isSvg': true,
      },
    ];

    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkNeutralText : const Color(0xFF4B5563),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
      ),
      child: Row(
        children: actions
            .map(
              (action) => Expanded(
                child: InkWell(
                  onTap: () => _handleQuickActionTap(action['label']!),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 48,
                          width: 48,
                          child: action['isSvg'] == true
                              ? SvgPicture.asset(
                                  action['asset']!,
                                  width: 48,
                                  height: 48,
                                  colorFilter: ColorFilter.mode(
                                    isDark ? Colors.white : Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                )
                              : Image.asset(
                                  isDark
                                      ? (action['darkAsset'] ?? action['asset'])!
                                      : action['asset']!,
                                  fit: BoxFit.contain,
                                ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          action['label']!,
                          style: labelStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
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

  List<Widget> _buildTagFilterSlivers(HomeAnnouncementsProvider provider) {
    // 始终显示标签筛选器（至少有"全部"选项）
    return [
      SliverToBoxAdapter(
        child: NoticeTagFilter(
          tags: provider.tags,
          selectedTagId: provider.selectedTagId,
          onTagSelected: (tagId) {
            debugPrint('HomePage: 选择标签 - tagId: $tagId');
            unawaited(provider.applyTagFilter(tagId));
          },
          isLoading: provider.isLoadingTags,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
