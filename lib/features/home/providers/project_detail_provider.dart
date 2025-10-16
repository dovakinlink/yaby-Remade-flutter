import 'package:flutter/material.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/home/data/models/project_detail_model.dart';
import 'package:yabai_app/features/home/data/repositories/project_repository.dart';

class ProjectDetailProvider extends ChangeNotifier {
  ProjectDetailProvider(this._repository);

  final ProjectRepository _repository;

  ProjectDetailModel? _project;
  ProjectDetailModel? get project => _project;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 加载项目详情
  Future<void> loadDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final detail = await _repository.fetchProjectDetail(id);
      _project = detail;
      _errorMessage = null;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _project = null;
    } catch (error) {
      _errorMessage = '加载项目详情失败: $error';
      _project = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新项目详情
  Future<void> refresh() async {
    if (_project == null) return;
    await loadDetail(_project!.id);
  }

  /// 清空状态
  void clear() {
    _project = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

