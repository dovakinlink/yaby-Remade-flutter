import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/ai/data/models/ai_project_model.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';

class AiQueryProvider extends ChangeNotifier {
  AiQueryProvider(this._repository);

  final AiRepository _repository;
  final _uuid = const Uuid();

  String _inputText = '';
  bool _isLoading = false;
  List<AiProjectModel> _projects = [];
  String? _errorMessage;
  bool _hasQueried = false;
  String? _sessionId; // 当前会话 ID

  String get inputText => _inputText;
  bool get isLoading => _isLoading;
  List<AiProjectModel> get projects => _projects;
  String? get errorMessage => _errorMessage;
  String? get sessionId => _sessionId;

  bool get hasProjects => _projects.isNotEmpty;
  bool get hasQueried => _hasQueried;

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
    _hasQueried = false;
    _sessionId = null;
    notifyListeners();
  }

  /// 生成新的会话 ID
  void generateNewSession() {
    _sessionId = _uuid.v4();
    notifyListeners();
  }

  /// 设置会话 ID（用于继续已有会话）
  void setSessionId(String? sessionId) {
    _sessionId = sessionId;
    notifyListeners();
  }

  /// 提交查询（使用新的 Spring Boot 代理接口）
  Future<void> submitQuery() async {
    if (_inputText.trim().isEmpty) {
      _errorMessage = '请输入查询内容';
      notifyListeners();
      return;
    }

    // 如果没有 sessionId，生成一个新的
    if (_sessionId == null || _sessionId!.isEmpty) {
      generateNewSession();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _repository.queryProjectsViaSpringBoot(
        _inputText.trim(),
        sessionId: _sessionId,
      );
      _projects = results;
      _errorMessage = null;
      _hasQueried = true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _projects = [];
      _hasQueried = true;
    } catch (e) {
      _errorMessage = 'AI 查询失败: $e';
      _projects = [];
      _hasQueried = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 提交查询（旧方法，直接调用 Python）
  Future<void> submitQueryLegacy() async {
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
      _hasQueried = true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _projects = [];
      _hasQueried = true;
    } catch (e) {
      _errorMessage = 'AI 查询失败: $e';
      _projects = [];
      _hasQueried = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

