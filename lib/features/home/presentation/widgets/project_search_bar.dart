import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';
import 'package:yabai_app/features/ai/providers/ai_query_provider.dart';
import 'package:yabai_app/features/ai/presentation/pages/ai_page.dart';

/// 项目搜索栏组件 - 重构版
/// 深色卡片样式，包含返回箭头、AI搜索开关胶囊、搜索按钮
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
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false; // 是否展开输入模式

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _showClearButton = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
    _isExpanded = widget.isSearchMode || (widget.initialValue?.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
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
      _isExpanded = false;
    });
    _focusNode.unfocus();
    widget.onCancel?.call();
  }

  /// 处理搜索提交
  void _handleSubmit() {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;

    _focusNode.unfocus();

    if (_isAiMode) {
      // AI 模式：跳转到 AI 搜索页面
      _navigateToAiPage(keyword);
    } else {
      // 普通模式：执行普通搜索
      widget.onSearch(keyword);
    }
  }

  /// 展开搜索输入
  void _expandSearch() {
    setState(() {
      _isExpanded = true;
    });
    _focusNode.requestFocus();
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 如果处于搜索模式或已展开，显示完整搜索界面
    if (_isExpanded || widget.isSearchMode) {
      return _buildExpandedSearchBar(isDarkMode);
    }

    // 默认显示简洁搜索框（点击展开）
    return _buildCollapsedSearchBar(isDarkMode);
  }

  /// 简洁模式搜索框（点击展开）
  Widget _buildCollapsedSearchBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _expandSearch,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? Colors.grey[700]!.withValues(alpha: 0.5)
                  : Colors.grey[300]!.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '搜索项目、标签、人员...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 15,
                  ),
                ),
              ),
              // AI 开关胶囊（简洁版）
              _buildAiTogglePill(isDarkMode, compact: true),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// 展开模式搜索框
  Widget _buildExpandedSearchBar(bool isDarkMode) {
    // 卡片容器颜色 - 根据主题模式调整
    final cardColor = isDarkMode
        ? const Color(0xFF2D2D35) // 深色模式
        : const Color(0xFFF5F5F7); // 浅色模式 - 浅灰色

    final borderColor = isDarkMode
        ? Colors.grey[700]!.withValues(alpha: 0.3)
        : Colors.grey[300]!.withValues(alpha: 0.8);

    // 输入框背景色
    final inputBgColor = isDarkMode
        ? const Color(0xFF3A3A42)
        : Colors.white;

    // 文字颜色
    final titleColor = isDarkMode ? Colors.white : Colors.grey[800];
    final hintColor = isDarkMode ? Colors.grey[500] : Colors.grey[500];
    final inputTextColor = isDarkMode ? Colors.white : Colors.grey[800];
    final iconColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 第一行：返回箭头 + 搜索关键词标题
            Row(
              children: [
                // 返回箭头
                GestureDetector(
                  onTap: _handleCancel,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_left,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 标题（当前搜索关键词或提示）
                Expanded(
                  child: Text(
                    _controller.text.isNotEmpty
                        ? _controller.text
                        : '搜索项目',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 第二行：AI搜索胶囊 + 搜索按钮
            Row(
              children: [
                // AI 搜索胶囊开关
                _buildAiTogglePill(isDarkMode, compact: false),
                const Spacer(),
                // 搜索按钮
                _buildSearchButton(),
              ],
            ),
            const SizedBox(height: 12),
            // 第三行：输入框
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(12),
                border: _isAiMode
                    ? Border.all(
                        color: AppColors.brandGreen.withValues(alpha: 0.6),
                        width: 1.5,
                      )
                    : Border.all(
                        color: isDarkMode
                            ? Colors.grey[600]!.withValues(alpha: 0.3)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    _isAiMode ? Icons.auto_awesome : Icons.search,
                    color: _isAiMode ? AppColors.brandGreen : hintColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: inputTextColor,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: _isAiMode
                            ? 'AI 智能匹配项目...'
                            : '输入搜索关键词...',
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                  if (_showClearButton)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.clear,
                          color: hintColor,
                          size: 18,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI 搜索胶囊开关
  Widget _buildAiTogglePill(bool isDarkMode, {required bool compact}) {
    // 胶囊背景色
    final pillColor = _isAiMode
        ? AppColors.brandGreen.withValues(alpha: isDarkMode ? 0.2 : 0.15)
        : (compact
            ? (isDarkMode ? Colors.grey[800] : Colors.grey[200])
            : (isDarkMode ? const Color(0xFF3A3A42) : Colors.white));

    // 胶囊边框色
    final borderColor = _isAiMode
        ? AppColors.brandGreen.withValues(alpha: 0.5)
        : (isDarkMode
            ? Colors.grey[600]!.withValues(alpha: 0.3)
            : Colors.grey[300]!);

    // 文字和图标颜色
    final textIconColor = _isAiMode
        ? AppColors.brandGreen
        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]);

    // 开关轨道颜色
    final trackColor = _isAiMode
        ? AppColors.brandGreen
        : (isDarkMode ? Colors.grey[600] : Colors.grey[400]);

    return GestureDetector(
      onTap: () {
        setState(() {
          _isAiMode = !_isAiMode;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 星星图标
            Icon(
              Icons.auto_awesome,
              color: textIconColor,
              size: compact ? 14 : 16,
            ),
            SizedBox(width: compact ? 4 : 6),
            // AI 搜索文字
            Text(
              'AI 搜索',
              style: TextStyle(
                color: textIconColor,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: compact ? 6 : 8),
            // 开关指示器
            Container(
              width: compact ? 32 : 36,
              height: compact ? 18 : 20,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: _isAiMode ? (compact ? 16 : 18) : 2,
                    top: 2,
                    child: Container(
                      width: compact ? 14 : 16,
                      height: compact ? 14 : 16,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 搜索按钮
  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: _handleSubmit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4A90D9), // 蓝色按钮
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90D9).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          '搜索',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
