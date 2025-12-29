import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';
import 'package:yabai_app/features/ai/providers/ai_query_provider.dart';
import 'package:yabai_app/features/ai/presentation/pages/ai_page.dart';

/// AI搜索框组件
/// 用于项目列表页面，点击后跳转到AI项目匹配页面
class AiSearchBar extends StatefulWidget {
  const AiSearchBar({super.key});

  @override
  State<AiSearchBar> createState() => _AiSearchBarState();
}

class _AiSearchBarState extends State<AiSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
  
  void _onTextFieldTap() {
    // 先取消其他所有输入框的焦点，避免键盘事件冲突
    FocusScope.of(context).unfocus();
    // 延迟后让当前输入框获得焦点
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _handleSubmit() {
    // 先取消当前焦点，避免键盘事件冲突
    FocusScope.of(context).unfocus();
    
    // 延迟执行，确保焦点已释放
    Future.microtask(() {
      if (!mounted) return;
      final query = _controller.text.trim();
      _navigateToAiPage(query);
    });
  }

  void _navigateToAiPage(String query) {
    final repository = context.read<AiRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) {
            final provider = AiQueryProvider(repository);
            if (query.isNotEmpty) {
              // 设置初始查询文本
              provider.updateInputText(query);
              // 延迟提交，确保页面已构建完成
              Future.microtask(() {
                provider.submitQuery();
              });
            }
            return provider;
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkScaffoldBackground
                : const Color(0xFFF8F9FA),
            body: SafeArea(
              top: false,
              bottom: false,
              child: AiPage(
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.brandGreen.withOpacity(0.2),
                  AppColors.brandGreen.withOpacity(0.1),
                ]
              : [
                  AppColors.brandGreen.withOpacity(0.1),
                  AppColors.brandGreen.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandGreen.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.psychology_outlined,
              color: AppColors.brandGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onTap: _onTextFieldTap,
                decoration: InputDecoration(
                  hintText: 'AI 智能匹配项目，例如：食管癌一线有合适的项目吗？',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : Colors.grey[600],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkNeutralText : Colors.black87,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSubmit(),
                maxLines: 1,
                keyboardType: TextInputType.text,
                enableInteractiveSelection: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _handleSubmit,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

