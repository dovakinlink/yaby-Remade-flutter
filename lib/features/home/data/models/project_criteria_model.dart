class ProjectCriteriaModel {
  const ProjectCriteriaModel({
    required this.id,
    required this.itemNo,
    required this.itemType,
    required this.content,
  });

  final int id;
  final int itemNo;
  final String itemType; // IN=入组, EX=排除
  final String content;

  factory ProjectCriteriaModel.fromJson(Map<String, dynamic> json) {
    return ProjectCriteriaModel(
      id: json['id'] as int,
      itemNo: json['itemNo'] as int,
      itemType: json['itemType'] as String,
      content: json['content'] as String,
    );
  }

  /// 是否为入组标准
  bool get isInclusion => itemType == 'IN';

  /// 是否为排除标准
  bool get isExclusion => itemType == 'EX';

  /// 类型显示文本
  String get typeLabel => isInclusion ? '入组' : '排除';
}

