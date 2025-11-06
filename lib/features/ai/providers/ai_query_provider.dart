import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/ai/data/models/ai_project_model.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';

class AiQueryProvider extends ChangeNotifier {
  AiQueryProvider(this._repository);

  final AiRepository _repository;

  String _inputText = '';
  bool _isLoading = false;
  List<AiProjectModel> _projects = [];
  String? _errorMessage;

  String get inputText => _inputText;
  bool get isLoading => _isLoading;
  List<AiProjectModel> get projects => _projects;
  String? get errorMessage => _errorMessage;

  bool get hasProjects => _projects.isNotEmpty;
  bool get hasQueried => _projects.isNotEmpty || _errorMessage != null;

  void updateInputText(String text) {
    _inputText = text;
    notifyListeners();
  }

  void clearInput() {
    _inputText = '';
    notifyListeners();
  }

  void clearResults() {
    _projects = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> submitQuery() async {
    if (_inputText.trim().isEmpty) {
      _errorMessage = '请输入查询内容';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _repository.queryProjects(_inputText.trim());
      _projects = results;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _projects = [];
    } catch (e) {
      _errorMessage = 'AI 查询失败: $e';
      _projects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

