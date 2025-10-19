import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/project_criteria_model.dart';
import 'package:yabai_app/features/screening/presentation/widgets/criteria_match_card.dart';
import 'package:yabai_app/features/screening/providers/screening_submit_provider.dart';

/// 入组条件匹配页面
class ScreeningSubmitPage extends StatelessWidget {
  const ScreeningSubmitPage({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.criteria,
  });

  static const routePath = 'screening-submit';
  static const routeName = 'screening-submit';

  final int projectId;
  final String projectName;
  final List<ProjectCriteriaModel> criteria;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ScreeningSubmitProvider>();

    // 分离入组和排除标准
    final inclusionCriteria =
        criteria.where((c) => c.isInclusion).toList();
    final exclusionCriteria =
        criteria.where((c) => c.isExclusion).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('入组条件匹配'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : const Color(0xFFF8F9FA),
      ),
      body: Column(
        children: [
          // 主体内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 项目名称
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '项目',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          projectName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkNeutralText
                                : AppColors.lightNeutralText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 入组标准
                  if (inclusionCriteria.isNotEmpty) ...[
                    _SectionHeader(
                      title: '入组标准',
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    ...inclusionCriteria.map((criterion) {
                      return CriteriaMatchCard(
                        criterion: criterion,
                        matchResult: provider.getMatchResult(criterion.id),
                        remark: provider.getRemark(criterion.id),
                        onMatchResultChanged: (isMatch) {
                          provider.setMatchResult(criterion.id, isMatch);
                        },
                        onRemarkChanged: (remark) {
                          provider.setRemark(criterion.id, remark);
                        },
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // 排除标准
                  if (exclusionCriteria.isNotEmpty) ...[
                    _SectionHeader(
                      title: '排除标准',
                      color: const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    ...exclusionCriteria.map((criterion) {
                      return CriteriaMatchCard(
                        criterion: criterion,
                        matchResult: provider.getMatchResult(criterion.id),
                        remark: provider.getRemark(criterion.id),
                        onMatchResultChanged: (isMatch) {
                          provider.setMatchResult(criterion.id, isMatch);
                        },
                        onRemarkChanged: (remark) {
                          provider.setRemark(criterion.id, remark);
                        },
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // 患者信息录入
                  _SectionHeader(
                    title: '患者信息',
                    color: AppColors.brandGreen,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 患者姓名简称
                        TextField(
                          decoration: InputDecoration(
                            labelText: '患者姓名简称',
                            hintText: '例如：张**',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : const Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkFieldBackground
                                : AppColors.lightFieldBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkNeutralText
                                : AppColors.lightNeutralText,
                          ),
                          onChanged: provider.setPatientNameAbbr,
                        ),
                        const SizedBox(height: 16),

                        // 住院号
                        TextField(
                          decoration: InputDecoration(
                            labelText: '住院号/门诊号',
                            hintText: '请输入患者住院号或门诊号',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : const Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkFieldBackground
                                : AppColors.lightFieldBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkNeutralText
                                : AppColors.lightNeutralText,
                          ),
                          onChanged: provider.setPatientInNo,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // 为底部按钮留空间
                ],
              ),
            ),
          ),

          // 底部提交按钮
          _SubmitButton(
            provider: provider,
            isDark: isDark,
            onSuccess: (screeningId) {
              // 返回上一页并显示成功提示
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('初筛提交成功（ID: $screeningId）'),
                  backgroundColor: AppColors.brandGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 区域标题
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.color,
    required this.isDark,
  });

  final String title;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
          ),
        ),
      ],
    );
  }
}

/// 底部提交按钮
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.provider,
    required this.isDark,
    required this.onSuccess,
  });

  final ScreeningSubmitProvider provider;
  final bool isDark;
  final ValueChanged<int> onSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 错误提示
          if (provider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: provider.clearError,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 提交按钮
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: provider.isSubmitting
                  ? null
                  : () async {
                      final screeningId = await provider.submit();
                      if (screeningId != null) {
                        onSuccess(screeningId);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.brandGreen.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: provider.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      '提交',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

