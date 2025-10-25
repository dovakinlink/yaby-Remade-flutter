/// 通知公告标签模型
class NoticeTagModel {
  final int id;
  final String tagCode;
  final String tagName;
  final String description;
  final int orderNo;

  NoticeTagModel({
    required this.id,
    required this.tagCode,
    required this.tagName,
    required this.description,
    required this.orderNo,
  });

  factory NoticeTagModel.fromJson(Map<String, dynamic> json) {
    return NoticeTagModel(
      id: json['id'] as int,
      tagCode: json['tagCode'] as String,
      tagName: json['tagName'] as String,
      description: json['description'] as String? ?? '',
      orderNo: json['orderNo'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tagCode': tagCode,
      'tagName': tagName,
      'description': description,
      'orderNo': orderNo,
    };
  }
}

