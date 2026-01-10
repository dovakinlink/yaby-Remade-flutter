import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/screening/data/models/enrollment_request_model.dart';
import 'package:yabai_app/features/screening/data/models/icf_request_model.dart';
import 'package:yabai_app/features/screening/data/models/screening_detail_model.dart';
import 'package:yabai_app/features/screening/data/models/status_log_model.dart';
import 'package:yabai_app/features/screening/data/repositories/screening_repository.dart';

/// 筛查详情页状态管理
class ScreeningDetailProvider extends ChangeNotifier {
  ScreeningDetailProvider({
    required ScreeningRepository repository,
    required this.screeningId,
  }) : _repository = repository;

  final ScreeningRepository _repository;
  final int screeningId;

  ScreeningDetailModel? _detail;
  List<StatusLogModel> _statusLogs = [];
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  ScreeningDetailModel? get detail => _detail;
  List<StatusLogModel> get statusLogs => _statusLogs;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  /// 加载筛查详情和状态历史
  Future<void> loadDetail() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchScreeningDetail(screeningId),
        _repository.fetchStatusHistory(screeningId),
      ]);
      _detail = results[0] as ScreeningDetailModel;
      _statusLogs = results[1] as List<StatusLogModel>;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = '加载失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 重新加载
  Future<void> reload() async {
    await loadDetail();
  }

  /// 更新状态
  Future<bool> updateStatus(String newStatus, {String? remark}) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateScreeningStatus(
        id: screeningId,
        status: newStatus,
        failRemark: remark,
      );
      await loadDetail(); // 重新加载
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = '更新状态失败: $e';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// 提交ICF
  Future<bool> submitIcf(IcfRequestModel request) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.submitIcf(screeningId, request);
      await loadDetail();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = '提交知情同意失败: $e';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// 提交入组
  Future<bool> submitEnrollment(EnrollmentRequestModel request) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.submitEnrollment(screeningId, request);
      await loadDetail();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = '提交入组信息失败: $e';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// 标记出组
  Future<bool> markAsExited() async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.markAsExited(screeningId);
      await loadDetail();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = '标记出组失败: $e';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// 获取当前状态允许的下一步操作
  List<String> get availableActions {
    if (_detail == null) return [];

    switch (_detail!.statusCode) {
      case 'PENDING':
        return ['CRC_REVIEW', 'MATCH_FAILED']; // 增加 MATCH_FAILED（审核不通过）
      case 'CRC_REVIEW':
        return ['MATCH_FAILED', 'ICF_FAILED', 'ICF_SIGNED'];
      case 'ICF_SIGNED':
        return ['ENROLLED'];
      case 'ENROLLED':
        return ['EXITED'];
      default:
        return [];
    }
  }
}

