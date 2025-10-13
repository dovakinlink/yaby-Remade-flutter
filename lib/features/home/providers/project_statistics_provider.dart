import 'package:flutter/material.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/home/data/models/project_statistics.dart';
import 'package:yabai_app/features/home/data/repositories/project_statistics_repository.dart';

class ProjectStatisticsProvider extends ChangeNotifier {
  ProjectStatisticsProvider(this._repository);

  final ProjectStatisticsRepository _repository;

  ProjectStatistics? _statistics;
  ProjectStatistics? get statistics => _statistics;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> load({bool force = false}) async {
    if (_isLoading || (_hasLoaded && !force)) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _statistics = await _repository.fetchStatistics();
      _hasLoaded = true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = '统计数据加载失败: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}
