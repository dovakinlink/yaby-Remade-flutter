class PostTagModel {
  final int id;
  final String tagCode;
  final String tagName;
  final String? description;
  final int orderNo;

  PostTagModel({
    required this.id,
    required this.tagCode,
    required this.tagName,
    this.description,
    required this.orderNo,
  });

  factory PostTagModel.fromJson(Map<String, dynamic> json) {
    return PostTagModel(
      id: json['id'] as int,
      tagCode: json['tagCode'] as String,
      tagName: json['tagName'] as String,
      description: json['description'] as String?,
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

class CreatePostRequest {
  final int hospitalId;
  final int tagId;
  final String title;
  final String contentHtml;
  final String? contentText;
  final List<int>? fileIds;

  CreatePostRequest({
    required this.hospitalId,
    required this.tagId,
    required this.title,
    required this.contentHtml,
    this.contentText,
    this.fileIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'hospitalId': hospitalId,
      'tagId': tagId,
      'title': title,
      'contentHtml': contentHtml,
      'contentText': contentText,
      'fileIds': fileIds,
    };
  }
}

