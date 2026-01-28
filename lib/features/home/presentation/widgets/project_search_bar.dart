import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';
import 'package:yabai_app/features/ai/providers/ai_query_provider.dart';
import 'package:yabai_app/features/ai/presentation/pages/ai_page.dart';
import 'package:yabai_app/features/auth/providers/user_profile_provider.dart';

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
  bool _showCancelButton = false; // 是否显示取消按钮

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _showClearButton = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _showCancelButton = widget.isSearchMode || (widget.initialValue?.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showCancelButton = _focusNode.hasFocus || _controller.text.isNotEmpty;
    });
  }

  void _onTextChanged() {
    setState(() {
      _showClearButton = _controller.text.isNotEmpty;
      _showCancelButton = _focusNode.hasFocus || _controller.text.isNotEmpty;
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
      _showCancelButton = false;
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

    // 显示搜索框和AI开关（搜索框上，AI开关下）
    return _buildSearchBarWithAiToggle(isDarkMode);
  }

  /// 搜索框 + AI开关（搜索框上，AI开关在左下角）
  Widget _buildSearchBarWithAiToggle(bool isDarkMode) {
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final inputTextColor = isDarkMode ? Colors.white : Colors.grey[800];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框 + 取消按钮
          Row(
            children: [
              Expanded(
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
                        color: hintColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: TextStyle(
                            color: inputTextColor,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: '搜索项目、标签、人员...',
                            hintStyle: TextStyle(
                              color: hintColor,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _handleSubmit(),
                          cursorColor: isDarkMode ? Colors.white : Colors.black,
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
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
              // 取消按钮
              if (_showCancelButton) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _handleCancel,
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: AppColors.brandGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // AI 开关胶囊（左下角）
          _buildAiTogglePill(isDarkMode, compact: false),
        ],
      ),
    );
  }

  /// AI 搜索胶囊开关
  Widget _buildAiTogglePill(bool isDarkMode, {required bool compact}) {
    // 检查是否为 CRC/CRA 用户
    final userProfile = context.read<UserProfileProvider>().profile;
    final isAiDisabled = userProfile?.isAiDisabled == true;

    // CRC/CRA 用户显示禁用状态
    if (isAiDisabled) {
      return _buildDisabledAiTogglePill(isDarkMode, compact: compact);
    }

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

  /// CRC/CRA 用户禁用状态的 AI 搜索胶囊
  Widget _buildDisabledAiTogglePill(bool isDarkMode, {required bool compact}) {
    // 禁用状态的颜色
    final pillColor = isDarkMode 
        ? Colors.grey[800]!.withValues(alpha: 0.5) 
        : Colors.grey[200]!.withValues(alpha: 0.7);
    final borderColor = isDarkMode 
        ? Colors.grey[700]!.withValues(alpha: 0.3) 
        : Colors.grey[300]!.withValues(alpha: 0.5);
    final textIconColor = isDarkMode ? Colors.grey[600] : Colors.grey[400];
    final trackColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return GestureDetector(
      onTap: () {
        // 点击时显示提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('当前角色暂不支持使用AI功能'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Opacity(
        opacity: 0.6,
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
              // 开关指示器（始终关闭状态）
              Container(
                width: compact ? 32 : 36,
                height: compact ? 18 : 20,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 2,
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
      ),
    );
  }

}
