import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/providers/ai_query_provider.dart';
import 'package:yabai_app/features/ai/presentation/widgets/ai_input_section.dart';
import 'package:yabai_app/features/ai/presentation/widgets/ai_project_card.dart';

class AiPage extends StatelessWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // 标题栏
        Container(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 64,
              alignment: Alignment.center,
              child: Text(
                'AI 项目匹配',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkNeutralText : Colors.black87,
                ),
              ),
            ),
          ),
        ),
        // 内容区域
        Expanded(
          child: Consumer<AiQueryProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 输入区域
                    AiInputSection(
                      onSubmit: () => provider.submitQuery(),
                      isLoading: provider.isLoading,
                    ),
                    const SizedBox(height: 24),
                    
                    // 结果区域
                    if (provider.isLoading)
                      _buildLoadingState()
                    else if (provider.errorMessage != null)
                      _buildErrorState(provider.errorMessage!, isDark)
                    else if (provider.hasProjects)
                      _buildResultsSection(provider, isDark)
                    else if (provider.hasQueried)
                      _buildEmptyState(isDark)
                    else
                      _buildInitialState(isDark),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'AI 正在分析中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.red[300] : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的项目',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请尝试调整查询条件',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 64,
              color: AppColors.brandGreen.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '输入患者信息',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI 将为您匹配合适的临床试验项目',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(AiQueryProvider provider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '匹配项目列表：',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkNeutralText : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...provider.projects.map((project) {
          return AiProjectCard(project: project);
        }),
      ],
    );
  }
}

