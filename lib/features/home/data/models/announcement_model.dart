import 'package:intl/intl.dart';

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    this.orgId,
    this.hospitalId,
    this.organizationName,
    this.hospitalName,
    required this.title,
    required this.noticeType,
    required this.isTop,
    required this.status,
    this.orderNo,
    this.contentHtml,
    this.contentText,
    this.createdBy,
    this.publisherName,
    this.publisherAvatarUrl,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const <AnnouncementAttachment>[],
    this.coverImageUrl,
    this.tagId,
    this.tagName,
  });

  final int id;
  final int? orgId;
  final int? hospitalId;
  final String? organizationName;
  final String? hospitalName;
  final String title;
  final int noticeType;
  final bool isTop;
  final int status;
  final int? orderNo;
  final String? contentHtml;
  final String? contentText;
  final int? createdBy;
  final String? publisherName;
  final String? publisherAvatarUrl;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AnnouncementAttachment> attachments;
  final String? coverImageUrl;
  final int? tagId;
  final String? tagName;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      orgId: json['orgId'] as int?,
      hospitalId: json['hospitalId'] as int?,
      organizationName:
          json['orgName'] as String? ?? json['organizationName'] as String?,
      hospitalName: json['hospitalName'] as String?,
      title: json['title'] as String? ?? '',
      noticeType: json['noticeType'] as int? ?? 0,
      isTop: json['top'] as bool? ?? false,
      status: json['status'] as int? ?? 0,
      orderNo: json['orderNo'] as int?,
      contentHtml: json['contentHtml'] as String?,
      contentText: json['contentText'] as String?,
      createdBy: json['createdBy'] as int?,
      publisherName:
          json['creatorName'] as String? ??
          json['publisherName'] as String? ??
          json['createdByName'] as String? ??
          json['author'] as String?,
      publisherAvatarUrl:
          json['creatorAvatar'] as String? ??
          json['publisherAvatar'] as String? ??
          json['avatarUrl'] as String? ??
          json['publisherAvatarUrl'] as String?,
      publishedAt: _tryParseDateTime(json['publishedAt']),
      createdAt: _parseDateTime(json['createdAt'] as String?),
      updatedAt: _parseDateTime(json['updatedAt'] as String?),
      attachments: _parseAttachments(json['attachments']),
      coverImageUrl:
          json['coverImageUrl'] as String? ??
          json['cover'] as String? ??
          json['bannerUrl'] as String?,
      tagId: json['tagId'] as int?,
      tagName: json['tagName'] as String?,
    );
  }

  bool get isOfficial => noticeType == 0;
  bool get isUserPost => noticeType == 1;

  String get displayContent {
    if (contentText != null && contentText!.trim().isNotEmpty) {
      return contentText!.trim();
    }
    return contentHtml ?? '';
  }

  String get noticeTypeLabel => isOfficial ? '通知公告' : '用户帖子';

  String get publishedLabel {
    final baseDate = publishedAt ?? createdAt;
    final now = DateTime.now();
    final difference = now.difference(baseDate);

    if (difference.inMinutes < 1) {
      return '刚刚';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟之前';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} 小时之前';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} 天之前';
    }
    return DateFormat('yyyy年MM月dd日').format(baseDate);
  }

  static DateTime _parseDateTime(String? value) {
    if (value == null) {
      return DateTime.now();
    }
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  static DateTime? _tryParseDateTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<AnnouncementAttachment> _parseAttachments(Object? value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(AnnouncementAttachment.fromJson)
          .toList(growable: false);
    }
    return const <AnnouncementAttachment>[];
  }

  String? get organizationDisplayName =>
      hospitalName?.trim().isNotEmpty == true ? hospitalName : organizationName;
}

class AnnouncementAttachment {
  const AnnouncementAttachment({
    this.id,
    this.fileId,
    required this.name,
    this.displayName,
    required this.url,
    this.mimeType,
    this.extension,
    this.size,
    this.readableSize,
    this.isImage = false,
    this.isPdf = false,
    this.isVideo = false,
  });

  final int? id;
  final int? fileId;
  final String name;
  final String? displayName;
  final String url;
  final String? mimeType;
  final String? extension;
  final int? size;
  final String? readableSize;
  final bool isImage;
  final bool isPdf;
  final bool isVideo;

  factory AnnouncementAttachment.fromJson(Map<String, dynamic> json) {
    return AnnouncementAttachment(
      id: json['id'] as int?,
      fileId: json['fileId'] as int?,
      name:
          json['name'] as String? ??
          json['displayName'] as String? ??
          json['filename'] as String? ??
          json['fileName'] as String? ??
          '附件',
      displayName:
          json['displayName'] as String? ?? json['filename'] as String?,
      url: json['url'] as String? ?? json['fileUrl'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? json['contentType'] as String?,
      extension: json['ext'] as String?,
      size: _readSize(json['size'] ?? json['sizeBytes']),
      readableSize: json['readableSize'] as String?,
      isImage: json['image'] as bool? ?? _inferImage(json),
      isPdf: json['pdf'] as bool? ?? _inferPdf(json),
      isVideo: json['video'] as bool? ?? _inferVideo(json),
    );
  }

  String get displayLabel =>
      displayName?.isNotEmpty == true ? displayName! : name;

  static int? _readSize(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  static bool _inferImage(Map<String, dynamic> json) {
    final mime = (json['mimeType'] ?? json['contentType']) as String?;
    if (mime != null && mime.contains('image')) {
      return true;
    }
    final ext = json['ext'] as String?;
    if (ext != null) {
      final lower = ext.toLowerCase();
      return lower.endsWith('jpg') ||
          lower.endsWith('jpeg') ||
          lower.endsWith('png') ||
          lower.endsWith('gif') ||
          lower.endsWith('webp');
    }
    return false;
  }

  static bool _inferPdf(Map<String, dynamic> json) {
    final mime = (json['mimeType'] ?? json['contentType']) as String?;
    if (mime != null && mime.contains('pdf')) {
      return true;
    }
    final ext = json['ext'] as String?;
    return ext != null && ext.toLowerCase().contains('pdf');
  }

  static bool _inferVideo(Map<String, dynamic> json) {
    final mime = (json['mimeType'] ?? json['contentType']) as String?;
    if (mime != null && mime.contains('video')) {
      return true;
    }
    final ext = json['ext'] as String?;
    if (ext != null) {
      final lower = ext.toLowerCase();
      return lower.contains('mp4') ||
          lower.contains('mov') ||
          lower.contains('avi') ||
          lower.contains('mkv');
    }
    return false;
  }
}
