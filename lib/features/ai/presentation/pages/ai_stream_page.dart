import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/providers/ai_stream_provider.dart';
import 'package:yabai_app/features/ai/presentation/widgets/thinking_cursor.dart';

/// AI 流式查询页面
/// 
/// 类似 Cursor Agent 风格的流式 AI 项目匹配页面
class AiStreamPage extends StatefulWidget {
  const AiStreamPage({
    super.key,
    this.onBack,
    this.initialQuery,
  });

  final VoidCallback? onBack;
  final String? initialQuery;

  @override
  State<AiStreamPage> createState() => _AiStreamPageState();
}

class _AiStreamPageState extends State<AiStreamPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // 如果有初始查询，设置并自动开始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        final provider = context.read<AiStreamProvider>();
        _inputController.text = widget.initialQuery!;
        provider.initWithQuery(widget.initialQuery!);
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final provider = context.read<AiStreamProvider>();
    if (provider.canSubmit) {
      provider.updateInputText(_inputController.text);
      provider.submitStreamQuery();
      _inputFocusNode.unfocus();
    }
  }

  void _handleCancel() {
    final provider = context.read<AiStreamProvider>();
    provider.cancelStream();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? AppColors.darkScaffoldBackground 
          : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: Consumer<AiStreamProvider>(
                builder: (context, provider, child) {
                  // 自动滚动到底部
                  if (provider.isStreaming && _scrollController.hasClients) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                      );
                    });
                  }

                  return SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 输入区域
                        _buildInputSection(provider, isDark),
                        const SizedBox(height: 24),
                        
                        // 输出区域
                        if (provider.hasStarted)
                          _buildOutputSection(provider, isDark)
                        else
                          _buildInitialState(isDark),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Stack(
              children: [
                // 返回按钮
                Positioned(
                  left: 4,
                  top: 8,
                  bottom: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: isDark ? AppColors.darkNeutralText : Colors.black87,
                    ),
                    onPressed: () {
                      final provider = context.read<AiStreamProvider>();
                      provider.cancelStream();
                      widget.onBack?.call();
                    },
                  ),
                ),
                // 标题
                Center(
                  child: Text(
                    'AI 智能匹配',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkNeutralText : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkDividerColor : Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(AiStreamProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.edit_note,
                color: AppColors.brandGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '描述患者信息',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkNeutralText : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 输入框
          Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkFieldBackground 
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? AppColors.darkFieldBorder 
                    : Colors.grey[300]!,
              ),
            ),
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              maxLines: 4,
              minLines: 3,
              enabled: !provider.isStreaming,
              onChanged: (text) {
                provider.updateInputText(text);
              },
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkNeutralText : Colors.black87,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: '请详细描述患者的病情信息，例如：\n• 诊断：肺腺癌 IV 期\n• EGFR 基因突变阳性\n• 年龄 55 岁，ECOG 评分 1 分',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark 
                      ? AppColors.darkSecondaryText 
                      : Colors.grey[500],
                  height: 1.5,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 按钮行
          Row(
            children: [
              // 取消按钮（流式进行中显示）
              if (provider.isStreaming) ...[
                OutlinedButton.icon(
                  onPressed: _handleCancel,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('停止'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // 发送按钮
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.canSubmit ? _handleSubmit : null,
                  icon: provider.isStreaming
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              isDark ? Colors.white70 : Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(provider.isStreaming ? '分析中...' : '开始匹配'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark 
                        ? Colors.grey[700] 
                        : Colors.grey[300],
                    disabledForegroundColor: isDark 
                        ? Colors.grey[500] 
                        : Colors.grey[500],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutputSection(AiStreamProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.brandGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI 分析结果',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkNeutralText : Colors.black87,
                ),
              ),
              const Spacer(),
              // 状态指示
              if (provider.isStreaming)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '分析中',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brandGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 错误信息
          if (provider.errorMessage != null)
            _buildErrorState(provider.errorMessage!, isDark),
          
          // 输出内容
          if (provider.hasOutput || provider.isStreaming)
            _buildStreamContent(provider, isDark)
          else if (!provider.isStreaming && provider.errorMessage == null)
            _buildEmptyOutput(isDark),
        ],
      ),
    );
  }

  Widget _buildStreamContent(AiStreamProvider provider, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkFieldBackground 
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: provider.isStreaming
              ? AppColors.brandGreen.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkFieldBorder : Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 流式文本内容
          SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: provider.streamOutput,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? AppColors.darkNeutralText : Colors.black87,
                    height: 1.6,
                  ),
                ),
                // 流式进行中显示闪烁光标
                if (provider.isStreaming)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: ThinkingCursor(
                      color: AppColors.brandGreen,
                      width: 2,
                      height: 18,
                    ),
                  ),
              ],
            ),
          ),
          
          // 完成状态
          if (!provider.isStreaming && provider.hasOutput) ...[
            const SizedBox(height: 16),
            Divider(
              color: isDark ? AppColors.darkDividerColor : Colors.grey[200],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '分析完成',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyOutput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 48,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              '等待 AI 分析...',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
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

  Widget _buildInitialState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 56,
                color: AppColors.brandGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '输入患者信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkNeutralText : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI 将为您实时匹配合适的临床试验项目',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // 提示标签
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildHintChip('流式输出', Icons.stream, isDark),
                _buildHintChip('实时分析', Icons.speed, isDark),
                _buildHintChip('智能匹配', Icons.auto_awesome, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintChip(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkCardBackground 
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? AppColors.darkDividerColor 
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
