import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';

/// AI 流式查询 Provider
/// 
/// 管理流式 AI 项目匹配的状态，支持打字机效果
class AiStreamProvider extends ChangeNotifier {
  AiStreamProvider(this._repository);

  final AiRepository _repository;
  final _uuid = const Uuid();

  // 输入状态
  String _inputText = '';
  
  // 流式输出状态
  String _streamOutput = '';
  bool _isStreaming = false;
  bool _hasStarted = false;  // 是否已开始过查询
  String? _errorMessage;
  String? _sessionId;
  
  // 流订阅
  StreamSubscription<String>? _streamSubscription;

  // Getters
  String get inputText => _inputText;
  String get streamOutput => _streamOutput;
  bool get isStreaming => _isStreaming;
  bool get hasStarted => _hasStarted;
  String? get errorMessage => _errorMessage;
  String? get sessionId => _sessionId;
  
  bool get hasOutput => _streamOutput.isNotEmpty;
  bool get canSubmit => _inputText.trim().isNotEmpty && !_isStreaming;

  /// 更新输入文本
  void updateInputText(String text) {
    _inputText = text;
    notifyListeners();
  }

  /// 清空输入
  void clearInput() {
    _inputText = '';
    notifyListeners();
  }

  /// 清空输出和状态
  void clearOutput() {
    _streamOutput = '';
    _errorMessage = null;
    _hasStarted = false;
    notifyListeners();
  }

  /// 重置所有状态
  void reset() {
    cancelStream();
    _inputText = '';
    _streamOutput = '';
    _isStreaming = false;
    _hasStarted = false;
    _errorMessage = null;
    _sessionId = null;
    notifyListeners();
  }

  /// 生成新的会话 ID
  void generateNewSession() {
    _sessionId = _uuid.v4();
    notifyListeners();
  }

  /// 取消当前流
  void cancelStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    if (_isStreaming) {
      _isStreaming = false;
      notifyListeners();
    }
  }

  /// 提交流式查询
  Future<void> submitStreamQuery() async {
    if (_inputText.trim().isEmpty) {
      _errorMessage = '请输入查询内容';
      notifyListeners();
      return;
    }

    // 取消之前的流
    cancelStream();

    // 如果没有 sessionId，生成一个新的
    if (_sessionId == null || _sessionId!.isEmpty) {
      generateNewSession();
    }

    // 清空之前的输出
    _streamOutput = '';
    _isStreaming = true;
    _hasStarted = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final stream = _repository.queryProjectsStream(
        userInput: _inputText.trim(),
        sessionId: _sessionId,
      );

      _streamSubscription = stream.listen(
        (textChunk) {
          // 追加文本片段
          _streamOutput += textChunk;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('🤖 [AI Stream Provider] 流错误: $error');
          _isStreaming = false;
          if (error is ApiException) {
            _errorMessage = error.message;
          } else {
            _errorMessage = 'AI 流式查询失败: $error';
          }
          notifyListeners();
        },
        onDone: () {
          debugPrint('🤖 [AI Stream Provider] 流完成');
          _isStreaming = false;
          notifyListeners();
        },
        cancelOnError: true,
      );
    } on ApiException catch (e) {
      _isStreaming = false;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _isStreaming = false;
      _errorMessage = 'AI 流式查询失败: $e';
      notifyListeners();
    }
  }

  /// 使用初始查询文本初始化
  void initWithQuery(String query) {
    _inputText = query;
    notifyListeners();
    
    // 自动开始查询
    if (query.isNotEmpty) {
      Future.microtask(() => submitStreamQuery());
    }
  }

  @override
  void dispose() {
    cancelStream();
    super.dispose();
  }
}
