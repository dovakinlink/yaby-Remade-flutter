import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/ai/data/models/xiaobai_patient_project_model.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';

/// 聊天消息模型
class ChatMessage {
  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isThinking = false,
  });

  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isThinking; // 是否为正在思考状态
}

/// 小白Agent - 聊天Provider
class XiaobaiChatProvider extends ChangeNotifier {
  XiaobaiChatProvider(this._repository);

  final AiRepository _repository;
  final _uuid = const Uuid();

  // 阶段1: 患者查询
  String _patientIdentifier = '';
  bool _isQueryingPatient = false;
  List<XiaobaiPatientProject> _projects = [];
  String? _patientError;

  // 阶段2: 项目选择
  XiaobaiPatientProject? _selectedProject;

  // 阶段3: AI对话
  String? _sessionId;
  List<ChatMessage> _messages = [];
  bool _isSendingMessage = false;
  String _inputText = '';
  String? _chatError;

  // Getters
  String get patientIdentifier => _patientIdentifier;
  bool get isQueryingPatient => _isQueryingPatient;
  List<XiaobaiPatientProject> get projects => _projects;
  String? get patientError => _patientError;
  bool get hasProjects => _projects.isNotEmpty;

  XiaobaiPatientProject? get selectedProject => _selectedProject;
  bool get hasSelectedProject => _selectedProject != null;

  String? get sessionId => _sessionId;
  List<ChatMessage> get messages => _messages;
  bool get isSendingMessage => _isSendingMessage;
  String get inputText => _inputText;
  String? get chatError => _chatError;

  // 判断当前阶段
  int get currentStage {
    if (_selectedProject != null) return 3; // 对话阶段
    if (_projects.isNotEmpty) return 2; // 项目选择阶段
    return 1; // 患者查询阶段
  }

  void updatePatientIdentifier(String value) {
    _patientIdentifier = value;
    notifyListeners();
  }

  void updateInputText(String value) {
    _inputText = value;
    notifyListeners();
  }

  void clearInputText() {
    _inputText = '';
    notifyListeners();
  }

  /// 查询患者项目
  Future<void> queryPatientProjects() async {
    if (_patientIdentifier.trim().isEmpty) {
      _patientError = '请输入患者姓名或住院号';
      notifyListeners();
      return;
    }

    _isQueryingPatient = true;
    _patientError = null;
    notifyListeners();

    try {
      final results = await _repository.queryPatientProjects(
        _patientIdentifier.trim(),
      );
      _projects = results;
      _patientError = null;

      if (_projects.isEmpty) {
        _patientError = '未查询到该患者的关联项目';
      }
    } on ApiException catch (e) {
      _patientError = e.message;
      _projects = [];
    } catch (e) {
      _patientError = '查询失败: $e';
      _projects = [];
    } finally {
      _isQueryingPatient = false;
      notifyListeners();
    }
  }

  /// 选择项目
  /// 返回 true 表示选择成功，false 表示项目未上传AI知识库
  bool selectProject(XiaobaiPatientProject project) {
    // 检查项目是否已上传AI知识库
    if (project.xiaobaiStatus == 0) {
      return false;
    }
    
    _selectedProject = project;
    _sessionId = _uuid.v4();
    _messages = [];
    _chatError = null;
    notifyListeners();
    return true;
  }

  /// 发送消息
  Future<void> sendMessage() async {
    if (_inputText.trim().isEmpty) {
      _chatError = '请输入问题';
      notifyListeners();
      return;
    }

    if (_selectedProject == null) {
      _chatError = '未选择项目';
      notifyListeners();
      return;
    }

    final userMessage = _inputText.trim();
    
    // 添加用户消息到列表
    _messages.add(ChatMessage(
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    
    // 添加"正在思考"的占位消息
    _messages.add(ChatMessage(
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isThinking: true,
    ));
    
    _inputText = '';
    _isSendingMessage = true;
    _chatError = null;
    notifyListeners();

    try {
      // 拼接项目前缀
      final questionWithPrefix = '${_selectedProject!.shortTitle}项目的患者，$userMessage';
      
      debugPrint('🤖 [Chat] 发送问题: $questionWithPrefix');

      final response = await _repository.askXiaobai(
        question: questionWithPrefix,
        projectId: _selectedProject!.projectId,
        patientName: _patientIdentifier,
        sessionId: _sessionId,
      );

      // 移除"正在思考"的占位消息，替换为真实的AI回复
      if (_messages.isNotEmpty && _messages.last.isThinking) {
        _messages.removeLast();
      }
      
      // 添加AI回复到列表
      _messages.add(ChatMessage(
        content: response.answer,
        isUser: false,
        timestamp: DateTime.now(),
        isThinking: false,
      ));
      _chatError = null;
    } on ApiException catch (e) {
      _chatError = e.message;
      // 移除"正在思考"的占位消息
      if (_messages.isNotEmpty && _messages.last.isThinking) {
        _messages.removeLast();
      }
      // 移除失败的用户消息
      if (_messages.isNotEmpty && _messages.last.isUser) {
        _messages.removeLast();
      }
    } catch (e) {
      _chatError = 'AI问答失败: $e';
      // 移除"正在思考"的占位消息
      if (_messages.isNotEmpty && _messages.last.isThinking) {
        _messages.removeLast();
      }
      // 移除失败的用户消息
      if (_messages.isNotEmpty && _messages.last.isUser) {
        _messages.removeLast();
      }
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// 重置到初始状态
  void reset() {
    _patientIdentifier = '';
    _isQueryingPatient = false;
    _projects = [];
    _patientError = null;
    _selectedProject = null;
    _sessionId = null;
    _messages = [];
    _isSendingMessage = false;
    _inputText = '';
    _chatError = null;
    notifyListeners();
  }

  /// 从历史会话初始化
  /// 用于在会话详情页继续对话
  void initFromSession({
    required String sessionId,
    required int projectId,
    required String projectShortTitle,
    String? patientIdentifier,
    List<ChatMessage>? historyMessages,
  }) {
    _sessionId = sessionId;
    _patientIdentifier = patientIdentifier ?? '';
    
    // 创建一个虚拟的项目对象用于聊天
    _selectedProject = XiaobaiPatientProject(
      projectId: projectId,
      projectName: projectShortTitle,
      shortTitle: projectShortTitle,
      patientInNo: patientIdentifier ?? '',
      patientNameAbbr: '',
      statusCode: '',
      statusText: '',
      xiaobaiStatus: 1, // 从历史会话初始化，假设已上传
    );
    
    // 加载历史消息
    _messages = historyMessages != null 
        ? List<ChatMessage>.from(historyMessages)
        : [];
    
    _chatError = null;
    _isSendingMessage = false;
    _inputText = '';
    
    notifyListeners();
  }

  /// 从项目直接初始化（用于项目详情页）
  /// 跳过患者查询和项目选择阶段，直接进入对话
  void initFromProject({
    required int projectId,
    required String projectName,
    String? projectShortTitle,
  }) {
    _sessionId = _uuid.v4();
    _patientIdentifier = ''; // 不需要患者信息
    
    // 创建虚拟项目对象
    _selectedProject = XiaobaiPatientProject(
      projectId: projectId,
      projectName: projectName,
      shortTitle: projectShortTitle ?? projectName,
      patientInNo: '',
      patientNameAbbr: '',
      statusCode: '',
      statusText: '',
      xiaobaiStatus: 1, // 从项目详情页进入，已通过检查
    );
    
    _messages = [];
    _chatError = null;
    _isSendingMessage = false;
    _inputText = '';
    
    notifyListeners();
  }
}
