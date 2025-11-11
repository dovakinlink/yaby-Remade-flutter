import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/widgets/animated_medical_background.dart';
import 'package:yabai_app/features/profile/data/models/user_profile_model.dart';
import 'package:yabai_app/features/profile/providers/user_profile_detail_provider.dart';
import 'package:yabai_app/features/im/providers/conversation_list_provider.dart';
import 'package:yabai_app/features/im/presentation/pages/chat_page.dart';

/// 用户详情页面
class UserProfileDetailPage extends StatefulWidget {
  const UserProfileDetailPage({
    super.key,
    required this.userId,
  });

  final int userId;

  static const routePath = 'user/:userId';
  static const routeName = 'user-profile-detail';

  @override
  State<UserProfileDetailPage> createState() => _UserProfileDetailPageState();
}

class _UserProfileDetailPageState extends State<UserProfileDetailPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '用户信息',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 动画背景
          const Positioned.fill(
            child: AnimatedMedicalBackground(
              baseColor: AppColors.brandGreen,
              density: 1.6,
              showHelix: true,
            ),
          ),
          // 渐变遮罩
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // 内容
          Consumer<UserProfileDetailProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return _buildLoading();
              }

              if (provider.errorMessage != null) {
                return _buildError(provider, isDark);
              }

              if (provider.profile == null) {
                return _buildEmpty();
              }

              return _buildContent(provider.profile!, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
      ),
    );
  }

  Widget _buildError(UserProfileDetailProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => provider.reload(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text('用户不存在'),
    );
  }

  Widget _buildContent(UserProfileModel profile, bool isDark) {
    return RefreshIndicator(
      onRefresh: () => context.read<UserProfileDetailProvider>().reload(),
      color: AppColors.brandGreen,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: 16,
          right: 16,
          bottom: 32,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 头像和基本信息（无卡片）
            _buildAvatarSection(profile, isDark),
            const SizedBox(height: 32),

            // 快捷操作按钮
            _buildQuickActions(profile, isDark),
            const SizedBox(height: 16),

            // 详细信息卡片
            _buildDetailInfoCard(profile, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 头像和基本信息区域（无卡片）
  Widget _buildAvatarSection(UserProfileModel profile, bool isDark) {
    final apiClient = context.read<ApiClient>();
    final avatarUrl = profile.avatar;
    final resolvedUrl = avatarUrl != null && avatarUrl.isNotEmpty
        ? apiClient.resolveUrlSync(avatarUrl)
        : null;

    return Column(
      children: [
        // 头像 - 增大并添加白色边框
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: resolvedUrl != null
              ? ClipOval(
                  child: Image.network(
                    resolvedUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    headers: apiClient.getAuthHeaders(),
                    errorBuilder: (context, error, stackTrace) {
                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.brandGreen,
                        ),
                      );
                    },
                  ),
                )
              : CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.brandGreen,
                  ),
                ),
        ),
        const SizedBox(height: 20),

        // 昵称 - 白色文字
        Text(
          profile.nickname.isNotEmpty ? profile.nickname : '未填写昵称',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 角色标签 - 白色背景
        if (profile.roleName.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              profile.roleName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.brandGreen,
              ),
            ),
          ),
      ],
    );
  }

  /// 快捷操作按钮
  Widget _buildQuickActions(UserProfileModel profile, bool isDark) {
    return Card(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 拨打电话
            Expanded(
              child: OutlinedButton.icon(
                onPressed: profile.phone.isNotEmpty 
                    ? () => _makePhoneCall(profile.phone)
                    : null,
                icon: const Icon(Icons.phone),
                label: const Text('拨打电话'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandGreen,
                  side: const BorderSide(color: AppColors.brandGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 发送私信
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _sendPrivateMessage(profile),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('发送私信'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandGreen,
                  side: const BorderSide(color: AppColors.brandGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 详细信息卡片
  Widget _buildDetailInfoCard(UserProfileModel profile, bool isDark) {
    return Card(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '详细信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightNeutralText,
              ),
            ),
            const SizedBox(height: 16),

            if (profile.username.isNotEmpty)
              _buildInfoRow('用户名', profile.username, Icons.person_outline, isDark),
            if (profile.phone.isNotEmpty)
              _buildInfoRow('手机号', profile.phone, Icons.phone_outlined, isDark),
            if (profile.email != null && profile.email!.isNotEmpty)
              _buildInfoRow('邮箱', profile.email!, Icons.email_outlined, isDark),

            const Divider(height: 24),

            if (profile.roleName.isNotEmpty)
              _buildInfoRow('业务角色', profile.roleName, Icons.work_outline, isDark),
            if (profile.systemRoleName.isNotEmpty)
              _buildInfoRow('系统角色', profile.systemRoleName, Icons.admin_panel_settings_outlined, isDark),

            const Divider(height: 24),

            if (profile.affiliationTypeText.isNotEmpty && profile.affiliationTypeText != '未知')
              _buildInfoRow('归属类型', profile.affiliationTypeText, Icons.business_outlined, isDark),
            if (profile.affiliationName.isNotEmpty && !profile.affiliationName.startsWith('未知'))
              _buildInfoRow('归属单位', profile.affiliationName, Icons.location_city_outlined, isDark),

            if (profile.departmentName != null && profile.departmentName!.isNotEmpty)
              _buildInfoRow('科室', profile.departmentName!, Icons.domain_outlined, isDark),

            const Divider(height: 24),

            _buildInfoRow(
              '注册时间',
              DateFormat('yyyy-MM-dd HH:mm').format(profile.createTime),
              Icons.calendar_today_outlined,
              isDark,
            ),
            _buildInfoRow(
              '更新时间',
              DateFormat('yyyy-MM-dd HH:mm').format(profile.updateTime),
              Icons.update_outlined,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.lightNeutralText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法拨打电话')),
        );
      }
    }
  }

  /// 发送私信 - 创建单聊会话
  void _sendPrivateMessage(UserProfileModel profile) async {
    try {
      // 显示加载提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在创建会话...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // 创建单聊会话
      final conversationProvider = context.read<ConversationListProvider>();
      final conversation = await conversationProvider.createSingleConversation(profile.id);

      // 跳转到聊天页面
      if (mounted) {
        context.pushNamed(
          ChatPage.routeName,
          pathParameters: {
            'convId': conversation.convId,
          },
          queryParameters: {
            'title': profile.nickname.isNotEmpty ? profile.nickname : profile.username,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建会话失败: $e')),
        );
      }
    }
  }
}

