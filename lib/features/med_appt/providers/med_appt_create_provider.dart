import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/med_appt/data/models/med_appt_create_request.dart';
import 'package:yabai_app/features/med_appt/data/repositories/med_appt_repository.dart';
import 'package:yabai_app/features/med_appt/utils/date_utils.dart' as med_date_utils;

class MedApptCreateProvider extends ChangeNotifier {
  MedApptCreateProvider(this._repository) {
    // 默认日期为下周一
    _planDate = med_date_utils.getNextMonday();
  }

  final MedApptRepository _repository;

  // 表单字段
  int? _projectId;
  String? _projectName;
  String _patientInNo = '';
  String _patientName = '';
  String _patientNameAbbr = '';
  late DateTime _planDate;
  String _timeSlot = 'AM'; // AM, PM, EVE
  int _durationMinutes = 120;
  int _coreValidHours = 0;
  String _drugText = '';
  String _note = '';

  // 表单状态
  bool _isSubmitting = false;
  String? _errorMessage;
  Map<String, String> _fieldErrors = {};

  // Getters
  int? get projectId => _projectId;
  String? get projectName => _projectName;
  String get patientInNo => _patientInNo;
  String get patientName => _patientName;
  String get patientNameAbbr => _patientNameAbbr;
  DateTime get planDate => _planDate;
  String get timeSlot => _timeSlot;
  int get durationMinutes => _durationMinutes;
  int get coreValidHours => _coreValidHours;
  String get drugText => _drugText;
  String get note => _note;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  Map<String, String> get fieldErrors => _fieldErrors;

  // Setters
  void setProject(int id, String name) {
    _projectId = id;
    _projectName = name;
    _clearFieldError('projectId');
    notifyListeners();
  }

  void setPatientInNo(String value) {
    _patientInNo = value.trim();
    _clearFieldError('patientInNo');
    notifyListeners();
  }

  void setPatientName(String value) {
    _patientName = value.trim();
    _clearFieldError('patientName');
    notifyListeners();
  }

  void setPatientNameAbbr(String value) {
    _patientNameAbbr = value.trim();
    notifyListeners();
  }

  void setPlanDate(DateTime date) {
    _planDate = date;
    _clearFieldError('planDate');
    notifyListeners();
  }

  void setTimeSlot(String value) {
    _timeSlot = value;
    _clearFieldError('timeSlot');
    notifyListeners();
  }

  void setDurationMinutes(int value) {
    _durationMinutes = value;
    _clearFieldError('durationMinutes');
    notifyListeners();
  }

  void setCoreValidHours(int value) {
    _coreValidHours = value;
    notifyListeners();
  }

  void setDrugText(String value) {
    _drugText = value.trim();
    _clearFieldError('drugText');
    notifyListeners();
  }

  void setNote(String value) {
    _note = value.trim();
    notifyListeners();
  }

  void _clearFieldError(String field) {
    if (_fieldErrors.containsKey(field)) {
      _fieldErrors.remove(field);
    }
  }

  /// 表单验证
  bool validate() {
    _fieldErrors.clear();
    _errorMessage = null;

    if (_projectId == null) {
      _fieldErrors['projectId'] = '请选择项目';
    }

    if (_patientInNo.isEmpty) {
      _fieldErrors['patientInNo'] = '请输入患者住院号';
    }

    if (_patientName.isEmpty) {
      _fieldErrors['patientName'] = '请输入患者姓名';
    }

    if (_timeSlot.isEmpty || !['AM', 'PM', 'EVE'].contains(_timeSlot)) {
      _fieldErrors['timeSlot'] = '请选择时段';
    }

    if (_durationMinutes <= 0) {
      _fieldErrors['durationMinutes'] = '用药时长必须大于0';
    }

    if (_drugText.isEmpty) {
      _fieldErrors['drugText'] = '请输入具体用药';
    }

    if (_fieldErrors.isNotEmpty) {
      _errorMessage = '请检查表单填写';
      notifyListeners();
      return false;
    }

    return true;
  }

  /// 提交表单
  Future<bool> submit() async {
    if (!validate()) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = MedApptCreateRequest(
        projectId: _projectId!,
        patientInNo: _patientInNo,
        patientName: _patientName,
        patientNameAbbr: _patientNameAbbr.isNotEmpty ? _patientNameAbbr : null,
        planDate: med_date_utils.formatDate(_planDate),
        timeSlot: _timeSlot,
        durationMinutes: _durationMinutes,
        coreValidHours: _coreValidHours > 0 ? _coreValidHours : null,
        drugText: _drugText,
        note: _note.isNotEmpty ? _note : null,
      );

      final id = await _repository.createMedAppt(request);
      debugPrint('预约创建成功，ID: $id');

      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      debugPrint('提交失败: ${e.message}');
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('提交异常: $e');
      _errorMessage = '提交失败: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// 重置表单
  void reset() {
    _projectId = null;
    _projectName = null;
    _patientInNo = '';
    _patientName = '';
    _patientNameAbbr = '';
    _planDate = med_date_utils.getNextMonday();
    _timeSlot = 'AM';
    _durationMinutes = 120;
    _coreValidHours = 0;
    _drugText = '';
    _note = '';
    _isSubmitting = false;
    _errorMessage = null;
    _fieldErrors = {};
    notifyListeners();
  }
}

