class FavoriteProjectModel {
  const FavoriteProjectModel({
    required this.favoriteId,
    required this.projectId,
    required this.projectName,
    this.shortTitle,
    this.sponsorName,
    required this.progressName,
    required this.signedCount,
    required this.totalSignCount,
    required this.customTags,
    this.note,
    required this.pinned,
    required this.createdAt,
  });

  final int favoriteId;
  final int projectId;
  final String projectName;
  final String? shortTitle;
  final String? sponsorName;
  final String progressName;
  final int signedCount;
  final int totalSignCount;
  final List<String> customTags;
  final String? note;
  final int pinned;
  final DateTime createdAt;

  factory FavoriteProjectModel.fromJson(Map<String, dynamic> json) {
    return FavoriteProjectModel(
      favoriteId: json['favoriteId'] as int,
      projectId: json['projectId'] as int,
      projectName: json['projectName'] as String,
      shortTitle: json['shortTitle'] as String?,
      sponsorName: json['sponsorName'] as String?,
      progressName: json['progressName'] as String,
      signedCount: json['signedCount'] as int,
      totalSignCount: json['totalSignCount'] as int,
      customTags: (json['customTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      note: json['note'] as String?,
      pinned: json['pinned'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 签约进度百分比（0-100）
  double get progressPercentage {
    if (totalSignCount <= 0) return 0;
    return (signedCount / totalSignCount * 100).clamp(0, 100);
  }

  /// 签约进度文本（如：15/50）
  String get progressText => '$signedCount/$totalSignCount';

  /// 是否置顶
  bool get isPinned => pinned == 1;
}

