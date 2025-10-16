class ProjectFileModel {
  const ProjectFileModel({
    required this.fileId,
    required this.fileName,
    required this.fileUrl,
    this.displayName,
    this.category,
    required this.sizeBytes,
    this.mimeType,
    required this.sortNo,
  });

  final int fileId;
  final String fileName;
  final String fileUrl;
  final String? displayName;
  final String? category;
  final int sizeBytes;
  final String? mimeType;
  final int sortNo;

  factory ProjectFileModel.fromJson(Map<String, dynamic> json) {
    return ProjectFileModel(
      fileId: json['fileId'] as int,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      displayName: json['displayName'] as String?,
      category: json['category'] as String?,
      sizeBytes: json['sizeBytes'] as int,
      mimeType: json['mimeType'] as String?,
      sortNo: json['sortNo'] as int,
    );
  }

  /// 获取显示名称（优先使用displayName，否则使用fileName）
  String get name => displayName ?? fileName;

  /// 格式化文件大小
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      final kb = (sizeBytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else if (sizeBytes < 1024 * 1024 * 1024) {
      final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    } else {
      final gb = (sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      return '$gb GB';
    }
  }

  /// 获取文件扩展名
  String get extension {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toUpperCase();
    }
    return '';
  }

  /// 是否为PDF文件
  bool get isPdf =>
      mimeType == 'application/pdf' || extension.toLowerCase() == 'pdf';

  /// 是否为图片文件
  bool get isImage {
    if (mimeType != null && mimeType!.startsWith('image/')) {
      return true;
    }
    final ext = extension.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// 是否为文档文件
  bool get isDocument {
    final ext = extension.toLowerCase();
    return ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'pdf'].contains(ext);
  }

  /// 获取分类显示文本
  String get categoryLabel {
    switch (category) {
      case 'protocol':
        return '研究方案';
      case 'icf':
        return '知情同意书';
      case 'crf':
        return '病例报告表';
      default:
        return category ?? '其他';
    }
  }
}

