import 'dart:async';
import 'package:flutter/material.dart';

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

    // 取消之前的定时器
    _debounce?.cancel();

    // 设置新的定时器
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
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '搜索项目、标签、人员...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                  suffixIcon: _showClearButton
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 15),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  final keyword = value.trim();
                  if (keyword.isNotEmpty) {
                    widget.onSearch(keyword);
                  }
                },
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

