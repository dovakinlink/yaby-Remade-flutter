/// 小白Agent - 患者关联项目模型
class XiaobaiPatientProject {
  const XiaobaiPatientProject({
    required this.projectId,
    required this.projectName,
    required this.shortTitle,
    required this.patientInNo,
    required this.patientNameAbbr,
    required this.statusCode,
    required this.statusText,
  });

  final int projectId;
  final String projectName;
  final String shortTitle;
  final String patientInNo;
  final String patientNameAbbr;
  final String statusCode;
  final String statusText;

  factory XiaobaiPatientProject.fromJson(Map<String, dynamic> json) {
    return XiaobaiPatientProject(
      projectId: json['projectId'] as int? ?? 0,
      projectName: json['projectName'] as String? ?? '',
      shortTitle: json['shortTitle'] as String? ?? '',
      patientInNo: json['patientInNo'] as String? ?? '',
      patientNameAbbr: json['patientNameAbbr'] as String? ?? '',
      statusCode: json['statusCode'] as String? ?? '',
      statusText: json['statusText'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'shortTitle': shortTitle,
      'patientInNo': patientInNo,
      'patientNameAbbr': patientNameAbbr,
      'statusCode': statusCode,
      'statusText': statusText,
    };
  }
}

