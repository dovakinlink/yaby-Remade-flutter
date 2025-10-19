import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/screening/data/models/screening_model.dart';
import 'package:yabai_app/features/screening/presentation/pages/screening_detail_page.dart';
import 'package:yabai_app/features/screening/providers/screening_list_provider.dart';
import 'package:yabai_app/features/screening/presentation/widgets/screening_status_filter.dart';

/// 筛查列表页面
class ScreeningListPage extends StatefulWidget {
  const ScreeningListPage({super.key});

  @override
  State<ScreeningListPage> createState() => _ScreeningListPageState();
}

class _ScreeningListPageState extends State<ScreeningListPage> {
  late final ScrollController _scrollController;

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
    if (!_scrollController.hasClients) return;

    final provider = context.read<ScreeningListProvider>();
    if (!provider.hasNext || provider.isLoadingMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ScreeningListProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        color: AppColors.brandGreen,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '我的筛查',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkNeutralText
                            : AppColors.lightNeutralText,
                      ),
                    ),
                    const Spacer(),
                    // 总数
                    if (provider.total > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '共 ${provider.total} 条',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 筛选栏
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  ScreeningStatusFilter(
                    currentFilter: provider.currentStatusFilter,
                    onFilterChanged: (statusCode) {
                      provider.setStatusFilter(statusCode);
                    },
                  ),
                  // 筛选提示
                  if (provider.currentStatusFilter != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '当前筛选：${_getStatusLabel(provider.currentStatusFilter)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // 加载中状态
            if (provider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                  ),
                ),
              ),

            // 错误状态
            if (provider.errorMessage != null && provider.screenings.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => provider.loadInitial(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 空状态
            if (provider.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getEmptyMessage(provider.currentStatusFilter),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 列表内容
            if (provider.screenings.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final screening = provider.screenings[index];
                      return _ScreeningCard(
                        screening: screening,
                        isDark: isDark,
                      );
                    },
                    childCount: provider.screenings.length,
                  ),
                ),
              ),

            // 加载更多指示器
            if (provider.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                      ),
                    ),
                  ),
                ),
              ),

            // 底部空白
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取状态标签
  String _getStatusLabel(String? statusCode) {
    switch (statusCode) {
      case 'PENDING':
        return '待审核';
      case 'CRC_REVIEW':
        return '审核中';
      case 'MATCH_FAILED':
        return '筛查失败';
      case 'ICF_SIGNED':
        return '已知情';
      case 'ICF_FAILED':
        return '知情失败';
      case 'ENROLLED':
        return '已入组';
      case 'EXITED':
        return '已出组';
      default:
        return '全部';
    }
  }

  /// 获取空状态提示
  String _getEmptyMessage(String? statusCode) {
    if (statusCode == null) {
      return '暂无筛查记录';
    }
    return '暂无${_getStatusLabel(statusCode)}的筛查记录';
  }
}

/// 筛查记录卡片
class _ScreeningCard extends StatelessWidget {
  const _ScreeningCard({
    required this.screening,
    required this.isDark,
  });

  final ScreeningModel screening;
  final bool isDark;

  Color _getStatusColor(String statusCode) {
    switch (statusCode) {
      case 'PENDING':
        return const Color(0xFFF59E0B); // 黄色 - 待审核
      case 'CRC_REVIEW':
        return const Color(0xFF3B82F6); // 蓝色 - 审核中
      case 'MATCH_FAILED':
      case 'ICF_FAILED':
        return const Color(0xFFEF4444); // 红色 - 失败
      case 'ICF_SIGNED':
        return const Color(0xFF8B5CF6); // 紫色 - 已知情
      case 'ENROLLED':
        return const Color(0xFF10B981); // 绿色 - 已入组
      case 'EXITED':
        return const Color(0xFF6B7280); // 灰色 - 已出组
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(screening.statusCode);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            ScreeningDetailPage.routeName,
            pathParameters: {'screeningId': screening.id.toString()},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：项目名称和状态
              Row(
                children: [
                  Expanded(
                    child: Text(
                      screening.projectName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkNeutralText
                            : AppColors.lightNeutralText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      screening.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 患者信息
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    screening.patientNameAbbr,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.medical_information_outlined,
                    size: 16,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    screening.patientInNo,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 时间信息
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(screening.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (screening.crcName != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.supervisor_account_outlined,
                      size: 16,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CRC: ${screening.crcName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

