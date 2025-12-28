import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/providers/xiaobai_chat_provider.dart';
import 'package:yabai_app/features/ai/presentation/widgets/xiaobai_chat_message.dart';

/// 小白Agent - 项目临床问答页面
/// 从项目详情页进入，直接针对项目进行问答
class XiaobaiProjectChatPage extends StatefulWidget {
  const XiaobaiProjectChatPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  final int projectId;
  final String projectName;

  @override
  State<XiaobaiProjectChatPage> createState() => _XiaobaiProjectChatPageState();
}

class _XiaobaiProjectChatPageState extends State<XiaobaiProjectChatPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffoldBackground : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildProjectCard(isDark),
            Expanded(
              child: Consumer<XiaobaiChatProvider>(
                builder: (context, provider, child) {
                  return _buildChatContent(provider, isDark);
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
                Positioned(
                  left: 4,
                  top: 8,
                  bottom: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? AppColors.darkNeutralText : Colors.black87,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Center(
                  child: Text(
                    '临床问答',
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

  Widget _buildProjectCard(bool isDark) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(), // 点击返回项目详情
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkDividerColor : Colors.grey[200]!,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder_open,
                color: AppColors.brandGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前项目',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.projectName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkNeutralText : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent(XiaobaiChatProvider provider, bool isDark) {
    // 当有新消息时滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Column(
      children: [
        // 聊天记录区
        Expanded(
          child: provider.messages.isEmpty
              ? _buildEmptyChatState(isDark)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    return XiaobaiChatMessage(
                      message: provider.messages[index],
                    );
                  },
                ),
        ),
        
        // 错误提示
        if (provider.chatError != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.chatError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        
        // 输入框
        _buildInputArea(provider, isDark),
      ],
    );
  }

  Widget _buildEmptyChatState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 64,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '开始提问',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '例如：入组标准是什么？',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(XiaobaiChatProvider provider, bool isDark) {
    _chatController.text = provider.inputText;
    _chatController.selection = TextSelection.fromPosition(
      TextPosition(offset: _chatController.text.length),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDividerColor : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              onChanged: provider.updateInputText,
              maxLines: null,
              decoration: InputDecoration(
                hintText: '输入您的问题...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: isDark 
                    ? AppColors.darkFieldBackground 
                    : Colors.grey[100],
              ),
              enabled: !provider.isSendingMessage,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: provider.isSendingMessage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
              onPressed: provider.isSendingMessage
                  ? null
                  : () => provider.sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}

