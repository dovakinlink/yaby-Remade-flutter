class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.projName,
    this.shortTitle,
    this.sponsorName,
    required this.progressName,
    required this.signedCount,
    required this.totalSignCount,
    required this.customTags,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String projName;
  final String? shortTitle;
  final String? sponsorName;
  final String progressName;
  final int signedCount;
  final int totalSignCount;
  final List<String> customTags;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int,
      projName: json['projName'] as String,
      shortTitle: json['shortTitle'] as String?,
      sponsorName: json['sponsorName'] as String?,
      progressName: json['progressName'] as String,
      signedCount: json['signedCount'] as int,
      totalSignCount: json['totalSignCount'] as int,
      customTags: (json['customTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 签约进度百分比（0-100）
  double get progressPercentage {
    if (totalSignCount <= 0) return 0;
    return (signedCount / totalSignCount * 100).clamp(0, 100);
  }

  /// 签约进度文本（如：15/50）
  String get progressText => '$signedCount/$totalSignCount';
}

