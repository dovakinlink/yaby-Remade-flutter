import 'package:yabai_app/features/learning/data/models/resource_file_model.dart';

class LearningResourceDetail {
  final int id;
  final String name;
  final int orderNo;
  final String? remark;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ResourceFile> files;

  const LearningResourceDetail({
    required this.id,
    required this.name,
    required this.orderNo,
    this.remark,
    required this.createdAt,
    required this.updatedAt,
    required this.files,
  });

  factory LearningResourceDetail.fromJson(Map<String, dynamic> json) {
    return LearningResourceDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      orderNo: json['orderNo'] as int? ?? 0,
      remark: json['remark'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      files: (json['files'] as List?)
              ?.map((file) => ResourceFile.fromJson(file as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 是否有文件
  bool get hasFiles => files.isNotEmpty;

  /// 文件总数
  int get fileCount => files.length;
}

