import 'package:yabai_app/features/screening/data/models/criteria_match_model.dart';

/// 提交初筛请求模型
class ScreeningRequestModel {
  const ScreeningRequestModel({
    required this.projectId,
    required this.patientInNo,
    required this.patientNameAbbr,
    required this.criteriaMatches,
  });

  final int projectId;
  final String patientInNo;
  final String patientNameAbbr;
  final List<CriteriaMatchModel> criteriaMatches;

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'patientInNo': patientInNo,
      'patientNameAbbr': patientNameAbbr,
      'criteriaMatches': criteriaMatches.map((m) => m.toJson()).toList(),
    };
  }
}

