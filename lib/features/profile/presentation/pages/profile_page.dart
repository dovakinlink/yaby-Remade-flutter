import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/widgets/animated_medical_background.dart';
import 'package:yabai_app/features/auth/data/models/user_profile.dart';
import 'package:yabai_app/features/auth/presentation/pages/login_page.dart';
import 'package:yabai_app/features/auth/providers/auth_session_provider.dart';
import 'package:yabai_app/features/auth/providers/user_profile_provider.dart';
import 'package:yabai_app/features/home/presentation/pages/announcement_detail_page.dart';
import 'package:yabai_app/features/home/presentation/widgets/feed_card.dart';
import 'package:yabai_app/features/profile/presentation/widgets/change_password_sheet.dart';
import 'package:yabai_app/features/profile/presentation/widgets/my_favorites_tab.dart';
import 'package:yabai_app/features/profile/providers/my_favorites_provider.dart';
import 'package:yabai_app/features/profile/providers/my_posts_provider.dart';
import 'package:yabai_app/features/im/data/local/im_database.dart';
import 'package:yabai_app/features/im/providers/websocket_provider.dart';
import 'package:yabai_app/features/app_update/data/services/app_update_service.dart';
import 'package:yabai_app/features/app_update/presentation/widgets/app_update_dialog.dart';

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
  bool _isLoggingOut = false;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController()..addListener(_handleScroll);

    // 刷新用户信息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().loadProfile();
      context.read<MyPostsProvider>().loadInitial();
      context.read<MyFavoritesProvider>().loadInitial();
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
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      if (_tabController.index == 0) {
        // 我的帖子
        final provider = context.read<MyPostsProvider>();
        if (provider.hasNext && !provider.isLoadingMore) {
          unawaited(provider.loadMore());
        }
      } else if (_tabController.index == 1) {
        // 我的收藏
        final provider = context.read<MyFavoritesProvider>();
        if (provider.hasNext && !provider.isLoadingMore) {
          unawaited(provider.loadMore());
        }
      }
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
                  Tab(text: '我的收藏'),
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
                  const MyFavoritesTab(),
                  _buildSettingsTab(isDark),
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
          final infoRows = _buildProfileInfoRows(profile, isDark);

          headerContent = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: resolvedAvatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          resolvedAvatarUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          headers: apiClient.getAuthHeaders(),
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarFallback(profile.displayName);
                          },
                        ),
                      )
                    : _buildAvatarFallback(profile.displayName),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkNeutralText : null,
                          ),
                    ),
                    if (profile.nickname != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@${profile.username}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.usernameBlue,
                            ),
                      ),
                    ],
                    if (infoRows.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: infoRows,
                      ),
                    ],
                  ],
                ),
              ),
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

  List<Widget> _buildProfileInfoRows(UserProfile profile, bool isDark) {
    final rows = <Widget>[];
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkNeutralText : const Color(0xFF0F172A),
    );

    void addInfo({required IconData icon, required String value}) {
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: AppColors.brandGreen),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: valueStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }

    final role = profile.primaryRoleName;
    if (role != null && role.isNotEmpty) {
      addInfo(icon: Icons.badge_outlined, value: role);
    }

    if (profile.affiliationType == 'HOSPITAL') {
      final hospital = profile.hospitalName;
      final department = profile.departmentName;
      if (hospital != null && hospital.isNotEmpty) {
        addInfo(icon: Icons.local_hospital_outlined, value: hospital);
      }
      if (department != null && department.isNotEmpty) {
        addInfo(icon: Icons.apartment_outlined, value: department);
      }
    } else {
      final company = profile.companyName;
      if (company != null && company.isNotEmpty) {
        addInfo(icon: Icons.business_outlined, value: company);
      }
    }

    return rows;
  }

  Widget _buildSettingsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      children: [
        _buildSettingsItem(
          icon: Icons.lock_reset_rounded,
          iconColor: AppColors.brandGreen,
          iconBackground: AppColors.brandGreen.withValues(alpha: 0.12),
          title: '修改密码',
          subtitle: '建议定期更新密码提升账户安全',
          onTap: _openChangePasswordSheet,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildSettingsItem(
          icon: Icons.system_update_rounded,
          iconColor: AppColors.brandGreen,
          iconBackground: AppColors.brandGreen.withValues(alpha: 0.12),
          title: '版本检测',
          subtitle: '检查是否有新版本可用',
          onTap: _checkAppUpdate,
          isDark: isDark,
          showLoader: _isCheckingUpdate,
        ),
        const SizedBox(height: 16),
        _buildSettingsItem(
          icon: Icons.logout_rounded,
          iconColor: Colors.redAccent,
          iconBackground: Colors.redAccent.withValues(alpha: 0.12),
          title: '退出登录',
          subtitle: '退出后需要重新登录',
          onTap: _confirmLogout,
          isDark: isDark,
          isDestructive: true,
          showLoader: _isLoggingOut,
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
    bool showLoader = false,
  }) {
    final tileColor = isDark ? AppColors.darkCardBackground : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? (isDark ? Colors.red.shade200 : Colors.redAccent)
                      : null,
                ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : const Color(0xFF6B7280),
                      ),
                )
              : null,
          trailing: showLoader
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive
                      ? (isDark ? Colors.red.shade200 : Colors.redAccent)
                      : (isDark ? Colors.white70 : const Color(0xFF94A3B8)),
                ),
          onTap: showLoader ? null : onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _openChangePasswordSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChangePasswordSheet(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码修改成功')),
      );
    }
  }

  /// 检测应用版本更新
  Future<void> _checkAppUpdate() async {
    if (_isCheckingUpdate) return;

    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final updateService = AppUpdateService(apiClient);
      final updateInfo = await updateService.checkUpdate();

      if (!mounted) return;

      debugPrint('📦 [ProfilePage] 更新检测结果: updateInfo=${updateInfo != null}, hasUpdate=${updateInfo?.hasUpdate}');

      if (updateInfo != null && updateInfo.hasUpdate) {
        // 有更新，显示更新对话框
        debugPrint('📦 [ProfilePage] 显示更新对话框');
        await AppUpdateDialog.show(context, updateInfo);
      } else if (updateInfo != null && !updateInfo.hasUpdate) {
        // 明确无更新（检测成功但无新版本），显示提示
        debugPrint('📦 [ProfilePage] 当前已是最新版本');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('当前已是最新版本'),
              backgroundColor: AppColors.brandGreen,
            ),
          );
        }
      } else {
        // updateInfo 为 null（网络错误、服务不可用等），静默处理
        debugPrint('📦 [ProfilePage] 更新检测失败（网络错误或服务不可用），静默处理');
      }
    } catch (e, stackTrace) {
      // 输出控制台日志，但不显示界面错误提示
      debugPrint('📦 [ProfilePage] 检测更新异常: $e');
      debugPrint('📦 [ProfilePage] 堆栈: $stackTrace');
      // 静默处理，不在界面显示错误提示
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '退出',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    final authSession = context.read<AuthSessionProvider>();
    final userProfile = context.read<UserProfileProvider>();
    final myPosts = context.read<MyPostsProvider>();

    try {
      // 清除认证信息
      await authSession.clear();
      await userProfile.clear();
      myPosts.clear();

      // 清除 IM 相关数据
      await _clearImData();

      if (!mounted) return;
      context.go(LoginPage.routePath);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('退出登录失败，请稍后重试')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  /// 清除 IM 相关数据
  Future<void> _clearImData() async {
    try {
      // 断开 WebSocket 连接
      final websocketProvider = context.read<WebSocketProvider>();
      websocketProvider.disconnect();
      
      // 清空本地 IM 数据库
      await ImDatabase.clearAllData();
      
      debugPrint('IM 数据已清除');
    } catch (e) {
      debugPrint('清除 IM 数据失败: $e');
      // 即使失败也继续登出流程
    }
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

}
