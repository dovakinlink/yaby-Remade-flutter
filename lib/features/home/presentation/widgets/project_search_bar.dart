import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';
import 'package:yabai_app/features/ai/providers/ai_query_provider.dart';
import 'package:yabai_app/features/ai/presentation/pages/ai_page.dart';

/// 项目搜索栏组件
class ProjectSearchBar extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onSearch;
  final VoidCallback? onCancel;
  final bool isSearchMode;

  const ProjectSearchBar({
    super.key,
    this.initialValue,
    required this.onSearch,
    this.onCancel,
    this.isSearchMode = false,
  });

  @override
  State<ProjectSearchBar> createState() => _ProjectSearchBarState();
}

class _ProjectSearchBarState extends State<ProjectSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;
  bool _showClearButton = false;
  bool _isAiMode = false; // AI 模式开关

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _showClearButton = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showClearButton = _controller.text.isNotEmpty;
    });

    // 如果是 AI 模式，不自动搜索
    if (_isAiMode) {
      return;
    }

    // 取消之前的定时器
    _debounce?.cancel();

    // 设置新的定时器（仅普通模式）
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final keyword = _controller.text.trim();
      if (keyword.isNotEmpty) {
        widget.onSearch(keyword);
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _showClearButton = false;
    });
  }

  void _handleCancel() {
    _controller.clear();
    setState(() {
      _showClearButton = false;
    });
    widget.onCancel?.call();
  }

  /// 处理搜索提交
  void _handleSubmit() {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;

    if (_isAiMode) {
      // AI 模式：跳转到 AI 搜索页面
      _navigateToAiPage(keyword);
    } else {
      // 普通模式：执行普通搜索
      widget.onSearch(keyword);
    }
  }

  /// 跳转到 AI 页面
  void _navigateToAiPage(String query) {
    final repository = context.read<AiRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) {
            final provider = AiQueryProvider(repository);
            if (query.isNotEmpty) {
              provider.updateInputText(query);
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 搜索输入框
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(22),
                border: _isAiMode
                    ? Border.all(
                        color: AppColors.brandGreen.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // 搜索图标
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(
                      _isAiMode ? Icons.psychology_outlined : Icons.search,
                      color: _isAiMode
                          ? AppColors.brandGreen
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      size: 20,
                    ),
                  ),
                  // 输入框
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: _isAiMode
                            ? 'AI 智能匹配项目...'
                            : '搜索项目、标签、人员...',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 15),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                  // AI 开关
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showClearButton) ...[
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: _clearSearch,
                          ),
                        ],
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isAiMode,
                            onChanged: (value) {
                              setState(() {
                                _isAiMode = value;
                              });
                            },
                            activeTrackColor: AppColors.brandGreen,
                            inactiveTrackColor: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[400],
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 取消按钮（搜索模式时显示）
          if (widget.isSearchMode) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _handleCancel,
              child: const Text(
                '取消',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

