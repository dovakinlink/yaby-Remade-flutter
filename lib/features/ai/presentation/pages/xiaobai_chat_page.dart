import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/providers/xiaobai_chat_provider.dart';
import 'package:yabai_app/features/ai/presentation/widgets/xiaobai_project_card.dart';
import 'package:yabai_app/features/ai/presentation/widgets/xiaobai_chat_message.dart';

class XiaobaiChatPage extends StatefulWidget {
  const XiaobaiChatPage({super.key});

  @override
  State<XiaobaiChatPage> createState() => _XiaobaiChatPageState();
}

class _XiaobaiChatPageState extends State<XiaobaiChatPage> {
  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _patientController.dispose();
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
            Expanded(
              child: Consumer<XiaobaiChatProvider>(
                builder: (context, provider, child) {
                  return _buildContent(provider, isDark);
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

  Widget _buildContent(XiaobaiChatProvider provider, bool isDark) {
    final stage = provider.currentStage;

    if (stage == 1) {
      return _buildPatientQueryStage(provider, isDark);
    } else if (stage == 2) {
      return _buildProjectSelectStage(provider, isDark);
    } else {
      return _buildChatStage(provider, isDark);
    }
  }

  // 阶段1: 患者查询
  Widget _buildPatientQueryStage(XiaobaiChatProvider provider, bool isDark) {
    _patientController.text = provider.patientIdentifier;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.person_search,
            size: 80,
            color: AppColors.brandGreen.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            '请输入患者信息',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkNeutralText : Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _patientController,
            onChanged: provider.updatePatientIdentifier,
            decoration: InputDecoration(
              hintText: '请输入患者姓名或住院号',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkFieldBackground : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (provider.patientError != null)
            Container(
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
                      provider.patientError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: provider.isQueryingPatient
                ? null
                : () => provider.queryPatientProjects(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: provider.isQueryingPatient
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    '查询',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 阶段2: 项目选择
  Widget _buildProjectSelectStage(XiaobaiChatProvider provider, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '找到 ${provider.projects.length} 个关联项目',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkNeutralText : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请选择要问答的项目',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ...provider.projects.map((project) {
            return XiaobaiProjectCard(
              project: project,
              onTap: () => provider.selectProject(project),
            );
          }),
        ],
      ),
    );
  }

  // 阶段3: AI对话
  Widget _buildChatStage(XiaobaiChatProvider provider, bool isDark) {
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
        // 已选项目信息卡片
        _buildSelectedProjectCard(provider, isDark),
        
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

  Widget _buildSelectedProjectCard(XiaobaiChatProvider provider, bool isDark) {
    final project = provider.selectedProject!;
    
    return Container(
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
              Icons.assignment,
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
                  project.shortTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkNeutralText : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            '例如：这个患者是否符合入组标准？',
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

