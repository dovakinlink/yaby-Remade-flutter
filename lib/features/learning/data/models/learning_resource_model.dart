class LearningResource {
  final int id;
  final String name;
  final int orderNo;
  final String? remark;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearningResource({
    required this.id,
    required this.name,
    required this.orderNo,
    this.remark,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      id: json['id'] as int,
      name: json['name'] as String,
      orderNo: json['orderNo'] as int? ?? 0,
      remark: json['remark'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'orderNo': orderNo,
      'remark': remark,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

