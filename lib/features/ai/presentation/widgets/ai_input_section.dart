import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/providers/ai_query_provider.dart';

class AiInputSection extends StatefulWidget {
  const AiInputSection({
    super.key,
    required this.onSubmit,
    required this.isLoading,
  });

  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  State<AiInputSection> createState() => _AiInputSectionState();
}

class _AiInputSectionState extends State<AiInputSection> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AiQueryProvider>();
    _controller = TextEditingController(text: provider.inputText);
    _focusNode = FocusNode();
    
    // 监听输入变化并更新 Provider
    _controller.addListener(() {
      context.read<AiQueryProvider>().updateInputText(_controller.text);
    });
    
    // 如果已有初始文本，标记为已初始化
    if (provider.inputText.isNotEmpty) {
      _isInitialized = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 如果Provider中的文本更新了但控制器还没有，同步一次
    if (!_isInitialized) {
      final provider = context.read<AiQueryProvider>();
      if (provider.inputText.isNotEmpty && _controller.text != provider.inputText) {
        _controller.text = provider.inputText;
        _isInitialized = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '描述的详细信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkNeutralText : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 4,
            enabled: !widget.isLoading,
            decoration: InputDecoration(
              hintText: '食管癌一线有合适的项目么，有没有合适的项目？',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.brandGreen,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkScaffoldBackground
                  : Colors.grey[50],
            ),
            style: TextStyle(
              color: isDark ? AppColors.darkNeutralText : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: AppColors.brandGreen.withValues(alpha: 0.5),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      '发送',
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

