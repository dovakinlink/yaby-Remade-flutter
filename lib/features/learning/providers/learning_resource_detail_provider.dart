import 'package:flutter/material.dart';
import 'package:yabai_app/features/learning/data/models/learning_resource_detail_model.dart';
import 'package:yabai_app/features/learning/data/repositories/learning_resource_repository.dart';

class LearningResourceDetailProvider extends ChangeNotifier {
  final LearningResourceRepository _repository;

  LearningResourceDetailProvider(this._repository);

  LearningResourceDetail? _detail;
  bool _isLoading = false;
  String? _errorMessage;

  LearningResourceDetail? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 加载详情
  Future<void> loadDetail(int resourceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final detail = await _repository.getResourceDetail(resourceId);
      _detail = detail;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('加载学习资源详情失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新
  Future<void> refresh(int resourceId) async {
    await loadDetail(resourceId);
  }

  /// 清除详情数据
  void clear() {
    _detail = null;
    _errorMessage = null;
    notifyListeners();
  }
}

