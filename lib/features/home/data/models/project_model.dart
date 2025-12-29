class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.projName,
    this.shortTitle,
    this.sponsorName,
    this.piName,
    this.indication,
    this.projectNo,
    required this.progressName,
    required this.signedCount,
    required this.totalSignCount,
    required this.customTags,
    required this.createdAt,
    required this.updatedAt,
    this.xiaobaiStatus = 0,
  });

  final int id;
  final String projName;
  final String? shortTitle;
  final String? sponsorName;
  final String? piName;
  final String? indication;
  final String? projectNo;
  final String progressName;
  final int signedCount;
  final int totalSignCount;
  final List<String> customTags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int xiaobaiStatus; // 0: 未上传AI知识库, 1: 已上传

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int,
      projName: json['projName'] as String,
      shortTitle: json['shortTitle'] as String?,
      sponsorName: json['sponsorName'] as String?,
      piName: json['piName'] as String?,
      indication: json['indication'] as String?,
      projectNo: parseProjectNo(json),
      progressName: json['progressName'] as String,
      signedCount: json['signedCount'] as int,
      totalSignCount: json['totalSignCount'] as int,
      customTags: (json['customTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      xiaobaiStatus: json['xiaobaiStatus'] as int? ?? 0,
    );
  }

  /// 签约进度百分比（0-100）
  double get progressPercentage {
    if (totalSignCount <= 0) return 0;
    return (signedCount / totalSignCount * 100).clamp(0, 100);
  }

  /// 签约进度文本（如：15/50）
  String get progressText => '$signedCount/$totalSignCount';

  /// 展示用的项目编号（后端缺失时退回到 ID）
  String get displayProjectNo {
    if (projectNo != null && projectNo!.isNotEmpty) {
      return projectNo!;
    }
    return '#$id';
  }

  static String? parseProjectNo(Map<String, dynamic> json) {
    final dynamic raw = json['projectNo'] ??
        json['projNo'] ??
        json['projCode'] ??
        json['projectCode'];
    if (raw == null) return null;
    if (raw is String) {
      return raw;
    }
    return raw.toString();
  }
}
