import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';
import 'package:yabai_app/features/ai/data/models/xiaobai_session_detail_model.dart';
import 'package:yabai_app/features/ai/providers/xiaobai_chat_provider.dart';
import 'package:yabai_app/features/ai/presentation/widgets/xiaobai_chat_message.dart';

/// 小白Agent - 会话详情页
/// 展示历史对话记录，并支持继续提问
class XiaobaiSessionDetailPage extends StatefulWidget {
  const XiaobaiSessionDetailPage({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<XiaobaiSessionDetailPage> createState() => _XiaobaiSessionDetailPageState();
}

class _XiaobaiSessionDetailPageState extends State<XiaobaiSessionDetailPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  String? _errorMessage;
  XiaobaiSessionDetailModel? _sessionDetail;

  @override
  void initState() {
    super.initState();
    _loadSessionDetail();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = context.read<AiRepository>();
      final detail = await repository.getXiaobaiSessionDetail(widget.sessionId);
      
      setState(() {
        _sessionDetail = detail;
        _isLoading = false;
      });

      // 转换历史消息并初始化Provider
      if (detail.messages.isNotEmpty) {
        final historyMessages = detail.messages.map((log) {
          return [
            ChatMessage(
              content: log.userQuestion,
              isUser: true,
              timestamp: log.createdAt,
            ),
            ChatMessage(
              content: log.aiResponse,
              isUser: false,
              timestamp: log.createdAt,
            ),
          ];
        }).expand((list) => list).toList();

        // 从第一条消息中提取项目信息
        context.read<XiaobaiChatProvider>().initFromSession(
          sessionId: detail.sessionId,
          projectId: detail.projectId ?? 0,
          projectShortTitle: detail.projectName ?? detail.title,
          historyMessages: historyMessages,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载会话详情失败: $e';
        _isLoading = false;
      });
    }
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
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: _buildErrorState(_errorMessage!, isDark),
              )
            else
              ..._buildChatContent(isDark),
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

  List<Widget> _buildChatContent(bool isDark) {
    return [
      // 会话标题卡片
      if (_sessionDetail != null)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkDividerColor : Colors.grey[200]!,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 会话主题
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chat,
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
                          '会话主题',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _sessionDetail!.title,
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
                ],
              ),
              
              // 项目信息（如果有）
              if (_sessionDetail!.projectId != null && _sessionDetail!.projectName != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _navigateToProjectDetail(_sessionDetail!.projectId!),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? AppColors.darkFieldBackground 
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark 
                            ? AppColors.darkDividerColor 
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.folder_open,
                            color: AppColors.brandGreen,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '关联项目',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _sessionDetail!.projectName!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkNeutralText : Colors.black87,
                                ),
                                maxLines: 1,
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
                ),
              ],
            ],
          ),
        ),
      
      // 聊天记录区
      Expanded(
        child: Consumer<XiaobaiChatProvider>(
          builder: (context, provider, child) {
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

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: provider.messages.length,
              itemBuilder: (context, index) {
                return XiaobaiChatMessage(
                  message: provider.messages[index],
                );
              },
            );
          },
        ),
      ),
      
      // 错误提示
      Consumer<XiaobaiChatProvider>(
        builder: (context, provider, child) {
          if (provider.chatError == null) return const SizedBox.shrink();
          
          return Container(
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
          );
        },
      ),
      
      // 输入框
      _buildInputArea(isDark),
    ];
  }

  Widget _buildInputArea(bool isDark) {
    return Consumer<XiaobaiChatProvider>(
      builder: (context, provider, child) {
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
      },
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.redAccent : Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkNeutralText : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSessionDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _navigateToProjectDetail(int projectId) {
    context.pushNamed(
      'project-detail',
      pathParameters: {'id': '$projectId'},
    );
  }
}

