/// 消息内容基类
abstract class MessageContent {
  Map<String, dynamic> toJson();
  
  static MessageContent fromJson(String msgType, Map<String, dynamic> json) {
    switch (msgType) {
      case 'TEXT':
        return TextContent.fromJson(json);
      case 'IMAGE':
        return ImageContent.fromJson(json);
      case 'FILE':
        return FileContent.fromJson(json);
      case 'AUDIO':
        return AudioContent.fromJson(json);
      case 'VIDEO':
        return VideoContent.fromJson(json);
      case 'CARD':
        return CardContent.fromJson(json);
      case 'PROJECT_CARD':
        return ProjectCardContent.fromJson(json);
      case 'SYSTEM':
        return SystemContent.fromJson(json);
      default:
        return TextContent(text: '[未知消息类型]');
    }
  }
}

/// 文本消息内容
class TextContent implements MessageContent {
  final String text;

  TextContent({required this.text});

  factory TextContent.fromJson(Map<String, dynamic> json) {
    return TextContent(
      text: json['text'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'text': text};
  }
}

/// 图片消息内容
class ImageContent implements MessageContent {
  final int? fileId;
  final String url;
  final int? width;
  final int? height;
  final int? size;

  ImageContent({
    this.fileId,
    required this.url,
    this.width,
    this.height,
    this.size,
  });

  factory ImageContent.fromJson(Map<String, dynamic> json) {
    return ImageContent(
      fileId: json['fileId'] as int?,
      url: json['url'] as String? ?? '',
      width: json['width'] as int?,
      height: json['height'] as int?,
      size: json['size'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'url': url,
      'width': width,
      'height': height,
      'size': size,
    };
  }
}

/// 文件消息内容
class FileContent implements MessageContent {
  final int? fileId;
  final String url;
  final String filename;
  final int? size;

  FileContent({
    this.fileId,
    required this.url,
    required this.filename,
    this.size,
  });

  factory FileContent.fromJson(Map<String, dynamic> json) {
    return FileContent(
      fileId: json['fileId'] as int?,
      url: json['url'] as String? ?? '',
      filename: json['filename'] as String? ?? '未知文件',
      size: json['size'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'url': url,
      'filename': filename,
      'size': size,
    };
  }
}

/// 语音消息内容
class AudioContent implements MessageContent {
  final int? fileId;
  final String url;
  final int? duration; // 秒

  AudioContent({
    this.fileId,
    required this.url,
    this.duration,
  });

  factory AudioContent.fromJson(Map<String, dynamic> json) {
    return AudioContent(
      fileId: json['fileId'] as int?,
      url: json['url'] as String? ?? '',
      duration: json['duration'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'url': url,
      'duration': duration,
    };
  }
}

/// 视频消息内容
class VideoContent implements MessageContent {
  final int? fileId;
  final String url;
  final int? duration; // 秒
  final String? cover; // 封面图URL

  VideoContent({
    this.fileId,
    required this.url,
    this.duration,
    this.cover,
  });

  factory VideoContent.fromJson(Map<String, dynamic> json) {
    return VideoContent(
      fileId: json['fileId'] as int?,
      url: json['url'] as String? ?? '',
      duration: json['duration'] as int?,
      cover: json['cover'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'url': url,
      'duration': duration,
      'cover': cover,
    };
  }
}

/// 卡片消息内容
class CardContent implements MessageContent {
  final String title;
  final String? desc;
  final String? url;

  CardContent({
    required this.title,
    this.desc,
    this.url,
  });

  factory CardContent.fromJson(Map<String, dynamic> json) {
    return CardContent(
      title: json['title'] as String? ?? '',
      desc: json['desc'] as String?,
      url: json['url'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'desc': desc,
      'url': url,
    };
  }
}

/// 系统消息内容
class SystemContent implements MessageContent {
  final String action;
  final int? userId;
  final String? userName;

  SystemContent({
    required this.action,
    this.userId,
    this.userName,
  });

  factory SystemContent.fromJson(Map<String, dynamic> json) {
    return SystemContent(
      action: json['action'] as String? ?? '',
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'userId': userId,
      'userName': userName,
    };
  }
}

/// 项目卡片消息内容
class ProjectCardContent implements MessageContent {
  final String cardType; // "project"
  final ProjectCardData project;
  final String snapshotAt;
  final List<CardAction> actions;

  ProjectCardContent({
    required this.cardType,
    required this.project,
    required this.snapshotAt,
    required this.actions,
  });

  factory ProjectCardContent.fromJson(Map<String, dynamic> json) {
    return ProjectCardContent(
      cardType: json['cardType'] as String? ?? 'project',
      project: ProjectCardData.fromJson(json['project'] as Map<String, dynamic>),
      snapshotAt: json['snapshotAt'] as String? ?? DateTime.now().toIso8601String(),
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => CardAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'cardType': cardType,
      'project': project.toJson(),
      'snapshotAt': snapshotAt,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }
}

/// 项目卡片数据
class ProjectCardData {
  final int id;
  final int? orgId;
  final String title;
  final String? phase;
  final String? tumorType;
  final String? lineOfTherapy;
  final int? siteCount;
  final String? status;
  final int? coverFileId;

  ProjectCardData({
    required this.id,
    this.orgId,
    required this.title,
    this.phase,
    this.tumorType,
    this.lineOfTherapy,
    this.siteCount,
    this.status,
    this.coverFileId,
  });

  factory ProjectCardData.fromJson(Map<String, dynamic> json) {
    return ProjectCardData(
      id: json['id'] as int,
      orgId: json['orgId'] as int?,
      title: json['title'] as String? ?? '',
      phase: json['phase'] as String?,
      tumorType: json['tumorType'] as String?,
      lineOfTherapy: json['lineOfTherapy'] as String?,
      siteCount: json['siteCount'] as int?,
      status: json['status'] as String?,
      coverFileId: json['coverFileId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orgId': orgId,
      'title': title,
      'phase': phase,
      'tumorType': tumorType,
      'lineOfTherapy': lineOfTherapy,
      'siteCount': siteCount,
      'status': status,
      'coverFileId': coverFileId,
    };
  }
}

/// 卡片操作
class CardAction {
  final String type; // "deeplink", "web", "event"
  final String label;
  final String? url;
  final String? name;
  final Map<String, dynamic>? params;

  CardAction({
    required this.type,
    required this.label,
    this.url,
    this.name,
    this.params,
  });

  factory CardAction.fromJson(Map<String, dynamic> json) {
    return CardAction(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      url: json['url'] as String?,
      name: json['name'] as String?,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'label': label,
      if (url != null) 'url': url,
      if (name != null) 'name': name,
      if (params != null) 'params': params,
    };
  }
}

