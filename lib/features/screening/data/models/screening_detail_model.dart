/// 筛查详情模型
class ScreeningDetailModel {
  const ScreeningDetailModel({
    required this.id,
    required this.orgId,
    this.hospitalId,
    required this.projectId,
    required this.projectName,
    required this.patientInNo,
    required this.patientNameAbbr,
    required this.researcherUserId,
    required this.researcherName,
    this.crcUserId,
    this.crcName,
    required this.statusCode,
    required this.statusText,
    this.failReasonDictId,
    this.failRemark,
    required this.createdAt,
    required this.updatedAt,
    required this.criteriaMatches,
  });

  final int id;
  final int orgId;
  final int? hospitalId;
  final int projectId;
  final String projectName;
  final String patientInNo;
  final String patientNameAbbr;
  final int researcherUserId;
  final String researcherName;
  final int? crcUserId;
  final String? crcName;
  final String statusCode;
  final String statusText;
  final int? failReasonDictId;
  final String? failRemark;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CriteriaMatchDetail> criteriaMatches;

  factory ScreeningDetailModel.fromJson(Map<String, dynamic> json) {
    return ScreeningDetailModel(
      id: json['id'] as int,
      orgId: json['orgId'] as int,
      hospitalId: json['hospitalId'] as int?,
      projectId: json['projectId'] as int,
      projectName: json['projectName'] as String,
      patientInNo: json['patientInNo'] as String,
      patientNameAbbr: json['patientNameAbbr'] as String,
      researcherUserId: json['researcherUserId'] as int,
      researcherName: json['researcherName'] as String,
      crcUserId: json['crcUserId'] as int?,
      crcName: json['crcName'] as String?,
      statusCode: json['statusCode'] as String,
      statusText: json['statusText'] as String,
      failReasonDictId: json['failReasonDictId'] as int?,
      failRemark: json['failRemark'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      criteriaMatches: (json['criteriaMatches'] as List)
          .map((e) => CriteriaMatchDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 入排条件匹配详情模型
class CriteriaMatchDetail {
  const CriteriaMatchDetail({
    required this.id,
    required this.criteriaType,
    required this.criteriaText,
    required this.matchResult,
    this.remark,
  });

  final int id;
  final String criteriaType; // IN=入组, EX=排除
  final String criteriaText;
  final String matchResult; // MATCH/UNMATCH/NA
  final String? remark;

  /// 是否为入组条件
  bool get isInclusion => criteriaType == 'IN';

  /// 是否匹配
  bool get isMatch => matchResult == 'MATCH';

  factory CriteriaMatchDetail.fromJson(Map<String, dynamic> json) {
    return CriteriaMatchDetail(
      id: json['id'] as int,
      criteriaType: json['criteriaType'] as String,
      criteriaText: json['criteriaText'] as String,
      matchResult: json['matchResult'] as String,
      remark: json['remark'] as String?,
    );
  }
}

