import 'package:flutter/material.dart';
import 'package:yabai_app/features/home/data/models/project_criteria_model.dart';
import 'package:yabai_app/features/screening/data/models/criteria_match_model.dart';
import 'package:yabai_app/features/screening/data/models/screening_request_model.dart';
import 'package:yabai_app/features/screening/data/repositories/screening_repository.dart';

/// 筛查提交表单状态管理
class ScreeningSubmitProvider extends ChangeNotifier {
  ScreeningSubmitProvider({
    required this.repository,
    required this.projectId,
    required this.criteria,
  }) {
    // 初始化每个条件的匹配状态
    for (final criterion in criteria) {
      _matchResults[criterion.id] = null;
      _remarks[criterion.id] = '';
    }
  }

  final ScreeningRepository repository;
  final int projectId;
  final List<ProjectCriteriaModel> criteria;

  // 患者信息
  String _patientNameAbbr = '';
  String _patientInNo = '';

  // 每个条件的匹配结果（true=MATCH, false=UNMATCH, null=未选择）
  final Map<int, bool?> _matchResults = {};

  // 每个条件的备注
  final Map<int, String> _remarks = {};

  // 提交状态
  bool _isSubmitting = false;
  String? _errorMessage;

  String get patientNameAbbr => _patientNameAbbr;
  String get patientInNo => _patientInNo;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// 设置患者姓名简称
  void setPatientNameAbbr(String value) {
    _patientNameAbbr = value.trim();
    notifyListeners();
  }

  /// 设置患者住院号
  void setPatientInNo(String value) {
    _patientInNo = value.trim();
    notifyListeners();
  }

  /// 设置条件匹配结果
  void setMatchResult(int criteriaId, bool isMatch) {
    _matchResults[criteriaId] = isMatch;
    notifyListeners();
  }

  /// 获取条件匹配结果
  bool? getMatchResult(int criteriaId) {
    return _matchResults[criteriaId];
  }

  /// 设置条件备注
  void setRemark(int criteriaId, String remark) {
    _remarks[criteriaId] = remark.trim();
    notifyListeners();
  }

  /// 获取条件备注
  String getRemark(int criteriaId) {
    return _remarks[criteriaId] ?? '';
  }

  /// 验证表单
  bool validate() {
    _errorMessage = null;

    // 验证患者信息
    if (_patientNameAbbr.isEmpty) {
      _errorMessage = '请填写患者姓名简称';
      notifyListeners();
      return false;
    }

    if (_patientInNo.isEmpty) {
      _errorMessage = '请填写患者住院号';
      notifyListeners();
      return false;
    }

    // 验证所有条件都已选择
    for (final criterion in criteria) {
      if (_matchResults[criterion.id] == null) {
        _errorMessage = '请完成所有入排条件的判断';
        notifyListeners();
        return false;
      }
    }

    return true;
  }

  /// 提交初筛
  Future<int?> submit() async {
    if (!validate()) {
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 构建匹配结果列表
      final matches = criteria.map((criterion) {
        final isMatch = _matchResults[criterion.id];
        final remark = _remarks[criterion.id];

        return CriteriaMatchModel(
          criteriaId: criterion.id,
          matchResult: isMatch! ? 'MATCH' : 'UNMATCH',
          remark: remark?.isNotEmpty == true ? remark : null,
        );
      }).toList();

      // 构建请求
      final request = ScreeningRequestModel(
        projectId: projectId,
        patientInNo: _patientInNo,
        patientNameAbbr: _patientNameAbbr,
        criteriaMatches: matches,
      );

      // 提交
      final screeningId = await repository.submitScreening(request);

      _isSubmitting = false;
      notifyListeners();

      return screeningId;
    } catch (error) {
      _isSubmitting = false;
      _errorMessage = error.toString();
      notifyListeners();
      return null;
    }
  }

  /// 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

