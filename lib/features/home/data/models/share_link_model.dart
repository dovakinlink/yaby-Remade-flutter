/// 项目分享链接数据模型
class ShareLinkModel {
  /// 分享码(12位唯一标识)
  final String code;
  
  /// 完整的分享链接 URL
  final String shareUrl;
  
  /// 过期时间(ISO 8601 格式)
  final String expireAt;

  const ShareLinkModel({
    required this.code,
    required this.shareUrl,
    required this.expireAt,
  });

  factory ShareLinkModel.fromJson(Map<String, dynamic> json) {
    return ShareLinkModel(
      code: json['code'] as String,
      shareUrl: json['shareUrl'] as String,
      expireAt: json['expireAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'shareUrl': shareUrl,
      'expireAt': expireAt,
    };
  }

  /// 将 ISO 8601 格式的过期时间转换为 DateTime 对象
  DateTime get expireDateTime {
    return DateTime.parse(expireAt);
  }
}

