import 'dart:convert';

/// AI 会话模型（用于会话列表展示）
class AiSessionModel {
  const AiSessionModel({
    required this.sessionId,
    required this.lastQuestion,
    required this.lastUpdated,
    required this.matchCount,
    this.status,
  });

  final String sessionId;
  final String lastQuestion;
  final DateTime lastUpdated;
  final int matchCount; // 项目匹配数
  final String? status;

  factory AiSessionModel.fromJson(Map<String, dynamic> json) {
    // 尝试从 aiResponse 解析项目数量
    int projectCount = json['matchCount'] as int? ?? 0;
    
    // 如果 matchCount 为 0，尝试从 aiResponse 解析
    if (projectCount == 0) {
      final aiResponseStr = json['aiResponse'] as String?;
      if (aiResponseStr != null && aiResponseStr.isNotEmpty) {
        projectCount = _parseProjectCount(aiResponseStr);
      }
    }

    return AiSessionModel(
      sessionId: json['sessionId'] as String? ?? '',
      lastQuestion: json['lastQuestion'] as String? ?? json['userQuestion'] as String? ?? '',
      lastUpdated: DateTime.parse(json['lastUpdated'] as String? ?? json['createdAt'] as String),
      matchCount: projectCount,
      status: json['status'] as String?,
    );
  }

  /// 从 aiResponse JSON字符串中解析项目数量
  static int _parseProjectCount(String aiResponseStr) {
    try {
      final aiResponse = jsonDecode(aiResponseStr) as Map<String, dynamic>;
      
      // 尝试从 search_trials.projects 获取（Python AI服务返回格式）
      final searchTrials = aiResponse['search_trials'] as Map<String, dynamic>?;
      if (searchTrials != null) {
        final projects = searchTrials['projects'] as List<dynamic>?;
        if (projects != null) {
          // 只计算 is_match 为 true 的项目
          final matchedCount = projects.where((p) {
            if (p is Map<String, dynamic>) {
              return p['is_match'] == true;
            }
            return false;
          }).length;
          return matchedCount > 0 ? matchedCount : projects.length;
        }
      }
      
      // 尝试从顶层 projects 获取
      final topProjects = aiResponse['projects'] as List<dynamic>?;
      if (topProjects != null) {
        return topProjects.length;
      }
      
      return 0;
    } catch (e) {
      // 解析失败，返回 0
      return 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'lastQuestion': lastQuestion,
      'lastUpdated': lastUpdated.toIso8601String(),
      'matchCount': matchCount,
      'status': status,
    };
  }
}

