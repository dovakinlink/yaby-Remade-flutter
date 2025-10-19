/// 筛查记录模型
class ScreeningModel {
  const ScreeningModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.patientInNo,
    required this.patientNameAbbr,
    required this.researcherName,
    this.crcName,
    required this.statusCode,
    required this.statusText,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int projectId;
  final String projectName;
  final String patientInNo;
  final String patientNameAbbr;
  final String researcherName;
  final String? crcName;
  final String statusCode;
  final String statusText;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ScreeningModel.fromJson(Map<String, dynamic> json) {
    return ScreeningModel(
      id: json['id'] as int,
      projectId: json['projectId'] as int,
      projectName: json['projectName'] as String,
      patientInNo: json['patientInNo'] as String,
      patientNameAbbr: json['patientNameAbbr'] as String,
      researcherName: json['researcherName'] as String,
      crcName: json['crcName'] as String?,
      statusCode: json['statusCode'] as String,
      statusText: json['statusText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

