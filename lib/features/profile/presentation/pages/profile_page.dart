import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/widgets/animated_medical_background.dart';
import 'package:yabai_app/features/auth/providers/user_profile_provider.dart';
import 'package:yabai_app/features/home/presentation/pages/announcement_detail_page.dart';
import 'package:yabai_app/features/home/presentation/widgets/feed_card.dart';
import 'package:yabai_app/features/profile/providers/my_posts_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const routePath = 'profile';
  static const routeName = 'profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController()..addListener(_handleScroll);

    // 刷新用户信息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().loadProfile();
      context.read<MyPostsProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_tabController.index != 0) return;
    if (!_scrollController.hasClients) return;

    final provider = context.read<MyPostsProvider>();
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 用户信息头部
            _buildUserHeader(context, isDark),
            // TabBar
            Container(
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.brandGreen,
                unselectedLabelColor:
                    isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                indicatorColor: AppColors.brandGreen,
                tabs: const [
                  Tab(text: '我的帖子'),
                  Tab(text: '我的筛选'),
                  Tab(text: '设置'),
                ],
              ),
            ),
            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyPostsTab(),
                  _buildPlaceholderTab('TODO: 我的筛选功能'),
                  _buildPlaceholderTab('TODO: 设置功能'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, bool isDark) {
    return Consumer<UserProfileProvider>(
      builder: (context, provider, child) {
        final profile = provider.profile;
        final double statusBarPadding = MediaQuery.of(context).padding.top;

        Widget headerContent;

        if (provider.isLoading && profile == null) {
          headerContent = const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
              ),
            ),
          );
        } else if (profile == null) {
          headerContent = Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  '加载用户信息失败',
                  style: TextStyle(
                    color:
                        isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        } else {
          final apiClient = context.read<ApiClient>();
          final resolvedAvatarUrl = profile.hasAvatar
              ? apiClient.resolveUrlSync(profile.avatar!)
              : null;

          headerContent = Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.4,
                  ),
                ),
                child: resolvedAvatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          resolvedAvatarUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          headers: apiClient.getAuthHeaders(),
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarFallback(profile.displayName);
                          },
                        ),
                      )
                    : _buildAvatarFallback(profile.displayName),
              ),
              const SizedBox(height: 16),
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
              ),
              if (profile.nickname != null) ...[
                const SizedBox(height: 4),
                Text(
                  '@${profile.username}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : Colors.grey[600],
                      ),
                ),
              ],
              if (!profile.isActive) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '账号已禁用',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[900],
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        final gradientOverlay = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.02),
          ],
        );

        return SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              const Positioned.fill(
                child: AnimatedMedicalBackground(
                  baseColor: AppColors.brandGreen,
                  density: 1.6,
                  showHelix: true,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: gradientOverlay),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: statusBarPadding + 32,
                  left: 24,
                  right: 24,
                  bottom: 32,
                ),
                child: headerContent,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarFallback(String displayName) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '用';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.brandGreen,
          fontSize: 36,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMyPostsTab() {
    return Consumer<MyPostsProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<UserProfileProvider>().refresh(),
              provider.refresh(),
            ]);
          },
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCardBackground
              : Colors.white,
          color: AppColors.brandGreen,
          child: _buildPostsList(provider),
        );
      },
    );
  }

  Widget _buildPostsList(MyPostsProvider provider) {
    if (provider.isInitialLoading && provider.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    if (provider.errorMessage != null && provider.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
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
      );
    }

    if (provider.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无发表内容',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.posts.length + (provider.hasNext ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        if (index == provider.posts.length) {
          return _buildLoadMoreIndicator(provider);
        }

        final post = provider.posts[index];
        return FeedCard(
          announcement: post,
          onTap: () {
            context.pushNamed(
              AnnouncementDetailPage.routeName,
              pathParameters: {'id': '${post.id}'},
              extra: post,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator(MyPostsProvider provider) {
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

  Widget _buildPlaceholderTab(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
