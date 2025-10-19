import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/screening/data/models/enrollment_request_model.dart';
import 'package:yabai_app/features/screening/data/models/icf_request_model.dart';
import 'package:yabai_app/features/screening/data/models/screening_detail_model.dart';
import 'package:yabai_app/features/screening/data/models/status_log_model.dart';
import 'package:yabai_app/features/screening/presentation/widgets/enrollment_submit_dialog.dart';
import 'package:yabai_app/features/screening/presentation/widgets/icf_submit_dialog.dart';
import 'package:yabai_app/features/screening/presentation/widgets/remark_input_dialog.dart';
import 'package:yabai_app/features/screening/providers/screening_detail_provider.dart';
import 'package:yabai_app/features/profile/presentation/pages/user_profile_detail_page.dart';

/// 筛查详情页面
class ScreeningDetailPage extends StatefulWidget {
  const ScreeningDetailPage({
    super.key,
    required this.screeningId,
  });

  final int screeningId;

  static const routePath = ':screeningId/detail';
  static const routeName = 'screening-detail';

  @override
  State<ScreeningDetailPage> createState() => _ScreeningDetailPageState();
}

class _ScreeningDetailPageState extends State<ScreeningDetailPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('筛查详情'),
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<ScreeningDetailProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoading();
          }

          if (provider.errorMessage != null) {
            return _buildError(provider, isDark);
          }

          if (provider.detail == null) {
            return _buildEmpty();
          }

          return _buildContent(provider, isDark);
        },
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

  Widget _buildError(ScreeningDetailProvider provider, bool isDark) {
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
      child: Text('筛查记录不存在'),
    );
  }

  Widget _buildContent(ScreeningDetailProvider provider, bool isDark) {
    return RefreshIndicator(
      onRefresh: () => provider.reload(),
      color: AppColors.brandGreen,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoCard(provider.detail!, isDark),
            const SizedBox(height: 16),
            _buildCriteriaMatchesCard(provider.detail!, isDark),
            const SizedBox(height: 16),
            _buildStatusTimelineCard(provider.statusLogs, isDark),
            const SizedBox(height: 16),
            _buildActionButtons(provider, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(ScreeningDetailModel detail, bool isDark) {
    return Card(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('项目名称', detail.projectName, isDark),
            _buildInfoRow('患者住院号', detail.patientInNo, isDark),
            _buildInfoRow('患者姓名', detail.patientNameAbbr, isDark),
            _buildClickableInfoRow('医生', detail.researcherName, detail.researcherUserId, isDark),
            if (detail.crcUserId != null)
              _buildClickableInfoRow('CRC', detail.crcName ?? '未分配', detail.crcUserId!, isDark)
            else
              _buildInfoRow('CRC', detail.crcName ?? '未分配', isDark),
            const SizedBox(height: 12),
            _buildStatusChip(detail.statusCode, detail.statusText, isDark),
            const SizedBox(height: 12),
            _buildInfoRow(
              '创建时间',
              DateFormat('yyyy-MM-dd HH:mm').format(detail.createdAt),
              isDark,
            ),
            _buildInfoRow(
              '更新时间',
              DateFormat('yyyy-MM-dd HH:mm').format(detail.updatedAt),
              isDark,
            ),
            if (detail.failRemark != null && detail.failRemark!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '失败备注',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.failRemark!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkSecondaryText : const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableInfoRow(String label, String value, int userId, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkSecondaryText : const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                debugPrint('点击筛查详情用户名: $label, value: $value, userId: $userId');
                context.pushNamed(
                  UserProfileDetailPage.routeName,
                  pathParameters: {'userId': userId.toString()},
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brandGreen,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String statusCode, String statusText, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(statusCode).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getStatusColor(statusCode).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(statusCode),
            size: 16,
            color: _getStatusColor(statusCode),
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(statusCode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaMatchesCard(ScreeningDetailModel detail, bool isDark) {
    return Card(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '入排条件匹配结果',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
              ),
            ),
            const SizedBox(height: 16),
            ...detail.criteriaMatches.map((match) => _buildCriteriaMatchItem(match, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaMatchItem(CriteriaMatchDetail match, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.darkDividerColor : AppColors.lightDividerColor,
        ),
        borderRadius: BorderRadius.circular(8),
        color: match.isMatch
            ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.1)
            : const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: match.isInclusion
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  match.isInclusion ? '入组' : '排除',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                match.isMatch ? Icons.check_circle : Icons.cancel,
                color: match.isMatch ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                match.matchResult,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: match.isMatch ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            match.criteriaText,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
            ),
          ),
          if (match.remark != null && match.remark!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '备注：${match.remark}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkSecondaryText : const Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTimelineCard(List<StatusLogModel> logs, bool isDark) {
    if (logs.isEmpty) return const SizedBox.shrink();

    return Card(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '状态流转历史',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
              ),
            ),
            const SizedBox(height: 16),
            ...logs.asMap().entries.map((entry) {
              final isLast = entry.key == logs.length - 1;
              return _buildTimelineItem(entry.value, isLast, isDark);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(StatusLogModel log, bool isLast, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.brandGreen,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isDark
                    ? AppColors.darkDividerColor
                    : AppColors.lightDividerColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(log.toStatus),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '操作人：${log.actedByName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkSecondaryText : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkSecondaryText : const Color(0xFF9CA3AF),
                  ),
                ),
                if (log.reasonRemark != null && log.reasonRemark!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkFieldBackground
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '备注：${log.reasonRemark}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ScreeningDetailProvider provider, bool isDark) {
    final actions = provider.availableActions;
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: actions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton(
            onPressed: provider.isUpdating
                ? null
                : () => _handleAction(context, provider, action),
            style: FilledButton.styleFrom(
              backgroundColor: _getActionColor(action),
              disabledBackgroundColor: _getActionColor(action).withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: provider.isUpdating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    _getActionText(action),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    ScreeningDetailProvider provider,
    String action,
  ) async {
    switch (action) {
      case 'CRC_REVIEW':
        await _showConfirmDialog(context, provider, action, '开始审核');
        break;
      case 'MATCH_FAILED':
        await _showRemarkDialog(context, provider, action, '标记筛查失败');
        break;
      case 'ICF_FAILED':
        await _showRemarkDialog(context, provider, action, '标记知情失败');
        break;
      case 'ICF_SIGNED':
        await _showIcfDialog(context, provider);
        break;
      case 'ENROLLED':
        await _showEnrollmentDialog(context, provider);
        break;
      case 'EXITED':
        await _showConfirmDialog(context, provider, action, '标记出组');
        break;
    }
  }

  Future<void> _showConfirmDialog(
    BuildContext context,
    ScreeningDetailProvider provider,
    String action,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('确认要$title吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _getActionColor(action),
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.updateStatus(action);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '操作成功' : provider.errorMessage ?? '操作失败'),
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _showRemarkDialog(
    BuildContext context,
    ScreeningDetailProvider provider,
    String action,
    String title,
  ) async {
    final remark = await showDialog<String?>(
      context: context,
      builder: (context) => RemarkInputDialog(title: title),
    );

    if (remark != null && context.mounted) {
      final success = await provider.updateStatus(action, remark: remark);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '操作成功' : provider.errorMessage ?? '操作失败'),
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _showIcfDialog(
    BuildContext context,
    ScreeningDetailProvider provider,
  ) async {
    final request = await showDialog<IcfRequestModel>(
      context: context,
      builder: (context) => const IcfSubmitDialog(),
    );

    if (request != null && context.mounted) {
      final success = await provider.submitIcf(request);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '知情同意提交成功' : provider.errorMessage ?? '提交失败'),
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _showEnrollmentDialog(
    BuildContext context,
    ScreeningDetailProvider provider,
  ) async {
    final request = await showDialog<EnrollmentRequestModel>(
      context: context,
      builder: (context) => const EnrollmentSubmitDialog(),
    );

    if (request != null && context.mounted) {
      final success = await provider.submitEnrollment(request);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '入组信息提交成功' : provider.errorMessage ?? '提交失败'),
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  String _getStatusText(String statusCode) {
    const statusMap = {
      'PENDING': '待CRC审核',
      'CRC_REVIEW': 'CRC审核中',
      'MATCH_FAILED': '筛查失败',
      'ICF_SIGNED': '已知情',
      'ICF_FAILED': '知情失败',
      'ENROLLED': '已入组',
      'EXITED': '已出组',
    };
    return statusMap[statusCode] ?? statusCode;
  }

  String _getActionText(String action) {
    const actionMap = {
      'CRC_REVIEW': '开始审核',
      'MATCH_FAILED': '标记筛查失败',
      'ICF_FAILED': '标记知情失败',
      'ICF_SIGNED': '提交知情同意',
      'ENROLLED': '提交入组信息',
      'EXITED': '标记出组',
    };
    return actionMap[action] ?? action;
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'MATCH_FAILED':
      case 'ICF_FAILED':
        return const Color(0xFFEF4444);
      case 'EXITED':
        return const Color(0xFFF59E0B);
      case 'CRC_REVIEW':
        return const Color(0xFF3B82F6);
      default:
        return AppColors.brandGreen;
    }
  }

  Color _getStatusColor(String statusCode) {
    switch (statusCode) {
      case 'PENDING':
        return const Color(0xFFF59E0B); // 橙色
      case 'CRC_REVIEW':
        return const Color(0xFF3B82F6); // 蓝色
      case 'MATCH_FAILED':
      case 'ICF_FAILED':
        return const Color(0xFFEF4444); // 红色
      case 'ICF_SIGNED':
      case 'ENROLLED':
        return const Color(0xFF10B981); // 绿色
      case 'EXITED':
        return const Color(0xFF6B7280); // 灰色
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _getStatusIcon(String statusCode) {
    switch (statusCode) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'CRC_REVIEW':
        return Icons.visibility;
      case 'MATCH_FAILED':
      case 'ICF_FAILED':
        return Icons.cancel;
      case 'ICF_SIGNED':
        return Icons.check_circle;
      case 'ENROLLED':
        return Icons.how_to_reg;
      case 'EXITED':
        return Icons.exit_to_app;
      default:
        return Icons.info;
    }
  }
}

