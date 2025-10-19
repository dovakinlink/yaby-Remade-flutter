/// 入排条件匹配结果模型
class CriteriaMatchModel {
  const CriteriaMatchModel({
    required this.criteriaId,
    required this.matchResult,
    this.remark,
  });

  final int criteriaId;
  final String matchResult; // MATCH, UNMATCH, NA
  final String? remark;

  Map<String, dynamic> toJson() {
    return {
      'criteriaId': criteriaId,
      'matchResult': matchResult,
      if (remark != null && remark!.isNotEmpty) 'remark': remark,
    };
  }

  CriteriaMatchModel copyWith({
    int? criteriaId,
    String? matchResult,
    String? remark,
  }) {
    return CriteriaMatchModel(
      criteriaId: criteriaId ?? this.criteriaId,
      matchResult: matchResult ?? this.matchResult,
      remark: remark ?? this.remark,
    );
  }
}

