/// ICF（知情同意）提交请求模型
class IcfRequestModel {
  const IcfRequestModel({
    required this.icfVersion,
    required this.icfDate,
    required this.signerName,
    this.fileIds,
  });

  final String icfVersion;
  final String icfDate; // yyyy-MM-dd
  final String signerName;
  final List<int>? fileIds;

  Map<String, dynamic> toJson() => {
        'icfVersion': icfVersion,
        'icfDate': icfDate,
        'signerName': signerName,
        'fileIds': fileIds,
      };
}

