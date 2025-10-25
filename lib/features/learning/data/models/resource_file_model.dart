class ResourceFile {
  final int fileId;
  final String displayName;
  final String filename;
  final String ext;
  final String mimeType;
  final int sizeBytes;
  final String url;
  final int sortNo;

  const ResourceFile({
    required this.fileId,
    required this.displayName,
    required this.filename,
    required this.ext,
    required this.mimeType,
    required this.sizeBytes,
    required this.url,
    required this.sortNo,
  });

  factory ResourceFile.fromJson(Map<String, dynamic> json) {
    return ResourceFile(
      fileId: json['fileId'] as int,
      displayName: json['displayName'] as String? ?? json['filename'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      ext: json['ext'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      url: json['url'] as String? ?? '',
      sortNo: json['sortNo'] as int? ?? 0,
    );
  }

  /// 格式化文件大小
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// 判断是否为PDF文件
  bool get isPdf => ext.toLowerCase() == '.pdf';

  /// 判断是否为图片文件
  bool get isImage {
    // 先检查 MIME 类型
    if (mimeType.toLowerCase().startsWith('image/')) {
      return true;
    }
    
    // 再检查扩展名（支持带点和不带点的情况）
    final normalizedExt = ext.toLowerCase().startsWith('.') 
        ? ext.toLowerCase() 
        : '.$ext'.toLowerCase();
    
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg']
        .contains(normalizedExt);
  }

  /// 判断是否为Office文档
  bool get isOfficeDoc =>
      ['.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx']
          .contains(ext.toLowerCase());
}

