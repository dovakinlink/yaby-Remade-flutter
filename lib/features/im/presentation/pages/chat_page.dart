import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/services/file_upload_service.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/features/im/providers/chat_provider.dart';
import 'package:yabai_app/features/im/presentation/widgets/message_bubble.dart';
import 'package:yabai_app/features/im/presentation/widgets/chat_input_bar.dart';
import 'package:yabai_app/features/im/data/models/conversation_model.dart';

/// 聊天页面
class ChatPage extends StatefulWidget {
  final String convId;
  final String? title;

  const ChatPage({
    super.key,
    required this.convId,
    this.title,
  });

  static const routePath = 'chat/:convId';
  static const routeName = 'im-chat';

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    
    // 页面加载时自动加载聊天记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final provider = context.read<ChatProvider>();
    if (!provider.hasMore || provider.isLoadingMore) return;

    // 滚动到顶部时加载更多
    if (_scrollController.position.pixels <= 100) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.title ?? provider.conversation?.title ?? '聊天'),
        backgroundColor: isDark ? AppColors.darkScaffoldBackground : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (provider.conversation?.type == ConversationType.group)
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {
                // TODO: 显示群组详情
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表区域
          Expanded(
            child: _buildMessageList(provider, isDark),
          ),
          // 输入区域
          ChatInputBar(
            controller: _textController,
            onSendText: (text) {
              provider.sendTextMessage(text);
              _textController.clear();
              // 滚动到底部
              _scrollToBottom();
            },
            onSendImage: () => _handleSendImage(),
            onSendFile: () => _handleSendFile(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatProvider provider, bool isDark) {
    if (provider.isInitialLoading && provider.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    if (provider.errorMessage != null && provider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadInitial(),
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

    if (provider.messages.isEmpty) {
      return Center(
        child: Text(
          '暂无消息',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.messages.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && provider.isLoadingMore) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                ),
              ),
            ),
          );
        }

        final messageIndex = provider.isLoadingMore ? index - 1 : index;
        final message = provider.messages[messageIndex];
        final isMe = message.senderUserId == provider.currentUserId;

        return MessageBubble(
          message: message,
          isMe: isMe,
        );
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// 处理发送图片
  Future<void> _handleSendImage() async {
    try {
      // 选择图片
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;

      // 显示上传进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _UploadProgressDialog(title: '正在上传图片'),
      );

      // 上传图片
      final apiClient = context.read<ApiClient>();
      final uploadService = FileUploadService(dio: apiClient.dio);
      final file = File(image.path);
      
      final uploadResult = await uploadService.uploadFile(file);
      
      // 获取图片尺寸
      final dimensions = await uploadService.getImageDimensions(file);

      // 关闭进度对话框
      if (mounted) Navigator.pop(context);

      // 发送图片消息
      if (mounted) {
        final provider = context.read<ChatProvider>();
        await provider.sendImageMessage(
          fileId: uploadResult['fileId'] as int,
          url: uploadResult['url'] as String,
          width: dimensions['width'],
          height: dimensions['height'],
          size: uploadResult['size'] as int?,
        );

        // 滚动到底部
        _scrollToBottom();
      }
    } catch (e) {
      // 关闭进度对话框
      if (mounted) Navigator.pop(context);
      
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送图片失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 处理发送文件
  Future<void> _handleSendFile() async {
    try {
      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final platformFile = result.files.first;
      if (platformFile.path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法获取文件路径')),
          );
        }
        return;
      }

      if (!mounted) return;

      // 显示上传进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _UploadProgressDialog(title: '正在上传文件'),
      );

      // 上传文件
      final apiClient = context.read<ApiClient>();
      final uploadService = FileUploadService(dio: apiClient.dio);
      final file = File(platformFile.path!);
      
      final uploadResult = await uploadService.uploadFile(file);

      // 关闭进度对话框
      if (mounted) Navigator.pop(context);

      // 发送文件消息
      if (mounted) {
        final provider = context.read<ChatProvider>();
        await provider.sendFileMessage(
          fileId: uploadResult['fileId'] as int,
          url: uploadResult['url'] as String,
          filename: uploadResult['filename'] as String,
          size: uploadResult['size'] as int?,
        );

        // 滚动到底部
        _scrollToBottom();
      }
    } catch (e) {
      // 关闭进度对话框（如果还开着）
      if (mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) {
          return route is! DialogRoute || !route.barrierDismissible;
        });
      }
      
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送文件失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 上传进度对话框
class _UploadProgressDialog extends StatelessWidget {
  final String title;

  const _UploadProgressDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

