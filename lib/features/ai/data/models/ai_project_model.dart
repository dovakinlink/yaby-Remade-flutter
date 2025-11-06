class AiProjectModel {
  const AiProjectModel({
    required this.projectCode,
    required this.projectName,
    required this.note,
    required this.isMatch,
  });

  final String projectCode;
  final String projectName;
  final String note;
  final bool isMatch;

  factory AiProjectModel.fromJson(Map<String, dynamic> json) {
    return AiProjectModel(
      projectCode: json['project_code'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      isMatch: json['is_match'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_code': projectCode,
      'project_name': projectName,
      'note': note,
      'is_match': isMatch,
    };
  }
}

