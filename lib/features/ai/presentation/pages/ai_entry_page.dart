import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';
import 'package:yabai_app/features/ai/providers/ai_query_provider.dart';
import 'package:yabai_app/features/ai/providers/ai_session_list_provider.dart';
import 'package:yabai_app/features/ai/presentation/pages/ai_page.dart';
import 'package:yabai_app/features/ai/presentation/pages/ai_session_list_page.dart';

class AiEntryPage extends StatelessWidget {
  const AiEntryPage({super.key});

  static const _introSections = [
    (
      '找项目',
      '根据患者的病历信息、诊断结果与用药史，AI将自动分析并推荐最匹配的临床试验项目，助力研究者快速锁定合适研究。'
    ),
    (
      '找患者',
      '输入项目的入排条件，AI将从患者数据库中智能筛选出符合条件的候选患者，显著提升招募效率与精准度。'
    ),
  ];

  static const _introTip =
      '提示：本功能基于AI智能匹配算法，结合机构数据库的临床数据与项目条件进行分析，所有结果仅供研究辅助参考。';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildHeader(isDark),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEntryButtons(context),
                const SizedBox(height: 24),
                _buildIntroCard(context, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          alignment: Alignment.center,
          child: Text(
            'AI 助手',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkNeutralText : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AiEntryButton(
            label: '找项目',
            onTap: () => _openAiProjects(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _AiEntryButton(
            label: '找患者',
            onTap: () => _showComingSoon(context),
          ),
        ),
      ],
    );
  }

  Widget _buildIntroCard(BuildContext context, bool isDark) {
    final cardColor =
        isDark ? AppColors.darkCardBackground : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // 机器人插图
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              'assets/images/g10.png',
              width: 140,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (title, content) in _introSections) ...[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  _introTip,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAiProjects(BuildContext context) {
    final repository = context.read<AiRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AiSessionListProvider(repository)..loadInitial(),
          child: const AiSessionListPage(),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('找患者功能正在研发中'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _AiEntryButton extends StatelessWidget {
  const _AiEntryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}

class _AiPageScaffold extends StatelessWidget {
  const _AiPageScaffold();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkScaffoldBackground : const Color(0xFFF8F9FA),
      body: SafeArea(
        top: false,
        bottom: false,
        child: AiPage(
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
