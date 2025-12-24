import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/models/ai_chat_log_model.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';
import 'package:yabai_app/features/ai/presentation/widgets/ai_project_card.dart';
import 'package:yabai_app/features/ai/data/models/ai_query_response.dart';
import 'dart:convert';

class AiSessionDetailPage extends StatefulWidget {
  const AiSessionDetailPage({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<AiSessionDetailPage> createState() => _AiSessionDetailPageState();
}

class _AiSessionDetailPageState extends State<AiSessionDetailPage> {
  List<AiChatLogModel>? _chatLogs;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessionHistory();
  }

  Future<void> _loadSessionHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = context.read<AiRepository>();
      final logs = await repository.getSessionHistory(widget.sessionId);
      setState(() {
        _chatLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载会话记录失败: $e';
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
            Expanded(
              child: _buildContent(isDark),
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
                    '对话详情',
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

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.darkNeutralText : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSessionHistory,
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

    if (_chatLogs == null || _chatLogs!.isEmpty) {
      return Center(
        child: Text(
          '暂无记录',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chatLogs!.length,
      itemBuilder: (context, index) {
        final log = _chatLogs![index];
        return _buildChatLogItem(log, isDark);
      },
    );
  }

  Widget _buildChatLogItem(AiChatLogModel log, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户问题
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: AppColors.brandGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    log.userQuestion,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.darkNeutralText : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // AI 回复
            if (log.status == 'SUCCESS' && log.aiResponse.isNotEmpty)
              ..._buildAiResponse(log.aiResponse, isDark)
            else if (log.status == 'ERROR')
              _buildErrorResponse(log.errorMessage ?? '查询失败', isDark)
            else
              _buildPendingResponse(isDark),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAiResponse(String aiResponse, bool isDark) {
    try {
      final responseData = jsonDecode(aiResponse) as Map<String, dynamic>;
      final aiResponseModel = AiQueryResponse.fromJson(responseData);
      final matchedProjects = aiResponseModel.searchTrials.projects
          .where((project) => project.isMatch)
          .toList();

      if (matchedProjects.isEmpty) {
        return [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  size: 18,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '未找到匹配的项目',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ];
      }

      return [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '找到 ${matchedProjects.length} 个匹配项目',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkNeutralText : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...matchedProjects.map((project) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AiProjectCard(project: project),
        )),
      ];
    } catch (e) {
      return [
        Text(
          'AI 响应: $aiResponse',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
          ),
        ),
      ];
    }
  }

  Widget _buildErrorResponse(String error, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 18,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.redAccent : Colors.red[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingResponse(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.orange),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '处理中...',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

