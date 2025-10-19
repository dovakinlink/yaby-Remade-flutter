/// 状态流转日志模型
class StatusLogModel {
  const StatusLogModel({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    this.reasonDictId,
    this.reasonRemark,
    required this.actedByName,
    required this.createdAt,
  });

  final int id;
  final String? fromStatus;
  final String toStatus;
  final int? reasonDictId;
  final String? reasonRemark;
  final String actedByName;
  final DateTime createdAt;

  factory StatusLogModel.fromJson(Map<String, dynamic> json) {
    return StatusLogModel(
      id: json['id'] as int,
      fromStatus: json['fromStatus'] as String?,
      toStatus: json['toStatus'] as String,
      reasonDictId: json['reasonDictId'] as int?,
      reasonRemark: json['reasonRemark'] as String?,
      actedByName: json['actedByName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

