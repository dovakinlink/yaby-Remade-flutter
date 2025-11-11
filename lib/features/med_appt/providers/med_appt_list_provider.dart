import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/med_appt/data/models/med_appt_model.dart';
import 'package:yabai_app/features/med_appt/data/repositories/med_appt_repository.dart';
import 'package:yabai_app/features/med_appt/utils/date_utils.dart' as med_date_utils;

class MedApptListProvider extends ChangeNotifier {
  MedApptListProvider(this._repository);

  final MedApptRepository _repository;

  // 选中的日期
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // 预约列表
  List<MedApptModel> _appointments = [];
  List<MedApptModel> get appointments => _appointments;

  // 分页信息
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _hasNext = false;

  bool get hasNext => _hasNext;
  int get totalCount => _totalCount;

  // 加载状态
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _loadMoreError;

  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get loadMoreError => _loadMoreError;

  /// 更新选中日期并重新加载
  void selectDate(DateTime date) {
    if (_selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day) {
      return;
    }
    _selectedDate = date;
    notifyListeners();
    loadInitial();
  }

  /// 初始加载
  Future<void> loadInitial() async {
    _isInitialLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final dateStr = med_date_utils.formatDate(_selectedDate);
      debugPrint('加载预约列表，日期: $dateStr');

      final response = await _repository.getWeekAppointments(
        date: dateStr,
        page: _currentPage,
        size: 20,
      );

      _appointments = response.data;
      _currentPage = response.page;
      _totalPages = response.pages;
      _totalCount = response.total;
      _hasNext = response.hasNext;
      _errorMessage = null;

      debugPrint('加载成功，共 $_totalCount 条记录');
    } on ApiException catch (e) {
      debugPrint('加载失败: ${e.message}');
      _errorMessage = e.message;
      _appointments = [];
    } catch (e) {
      debugPrint('加载异常: $e');
      _errorMessage = '加载失败: ${e.toString()}';
      _appointments = [];
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext) {
      return;
    }

    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final dateStr = med_date_utils.formatDate(_selectedDate);
      final nextPage = _currentPage + 1;

      final response = await _repository.getWeekAppointments(
        date: dateStr,
        page: nextPage,
        size: 20,
      );

      _appointments.addAll(response.data);
      _currentPage = response.page;
      _totalPages = response.pages;
      _hasNext = response.hasNext;
      _loadMoreError = null;

      debugPrint('加载更多成功，当前共 ${_appointments.length} 条记录');
    } on ApiException catch (e) {
      debugPrint('加载更多失败: ${e.message}');
      _loadMoreError = e.message;
    } catch (e) {
      debugPrint('加载更多异常: $e');
      _loadMoreError = '加载失败: ${e.toString()}';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 刷新
  Future<void> refresh() async {
    _currentPage = 1;
    await loadInitial();
  }

  /// 按日期分组预约
  Map<String, List<MedApptModel>> get appointmentsByDate {
    final Map<String, List<MedApptModel>> grouped = {};
    for (var appt in _appointments) {
      if (!grouped.containsKey(appt.planDate)) {
        grouped[appt.planDate] = [];
      }
      grouped[appt.planDate]!.add(appt);
    }
    return grouped;
  }

  /// 获取日期的预约数量（用于日历标记）
  int getAppointmentCountForDate(DateTime date) {
    final dateStr = med_date_utils.formatDate(date);
    return _appointments.where((appt) => appt.planDate == dateStr).length;
  }

  /// 确认预约
  Future<bool> confirmAppointment(int apptId) async {
    try {
      await _repository.confirmMedAppt(apptId);
      
      // 更新本地列表中的预约状态
      final index = _appointments.indexWhere((appt) => appt.id == apptId);
      if (index != -1) {
        // 创建一个新的预约对象，状态改为CONFIRMED
        final updatedAppt = MedApptModel(
          id: _appointments[index].id,
          orgId: _appointments[index].orgId,
          projectId: _appointments[index].projectId,
          projName: _appointments[index].projName,
          patientInNo: _appointments[index].patientInNo,
          patientName: _appointments[index].patientName,
          patientNameAbbr: _appointments[index].patientNameAbbr,
          researcherPersonId: _appointments[index].researcherPersonId,
          researcherName: _appointments[index].researcherName,
          crcPersonId: _appointments[index].crcPersonId,
          crcName: _appointments[index].crcName,
          nursePersonId: _appointments[index].nursePersonId,
          nurseName: _appointments[index].nurseName,
          planDate: _appointments[index].planDate,
          planWeekMonday: _appointments[index].planWeekMonday,
          timeSlot: _appointments[index].timeSlot,
          durationMinutes: _appointments[index].durationMinutes,
          coreValidHours: _appointments[index].coreValidHours,
          drugText: _appointments[index].drugText,
          note: _appointments[index].note,
          status: 'CONFIRMED', // 更新状态
          source: _appointments[index].source,
          createdBy: _appointments[index].createdBy,
          createdAt: _appointments[index].createdAt,
          updatedBy: _appointments[index].updatedBy,
          updatedAt: _appointments[index].updatedAt,
        );
        _appointments[index] = updatedAppt;
        notifyListeners();
      }
      
      return true;
    } on ApiException catch (e) {
      debugPrint('确认预约失败: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('确认预约异常: $e');
      return false;
    }
  }
}

