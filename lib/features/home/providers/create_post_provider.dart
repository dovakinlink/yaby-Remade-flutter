import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/home/data/models/post_tag_model.dart';
import 'package:yabai_app/features/home/data/repositories/post_repository.dart';

class CreatePostProvider with ChangeNotifier {
  final PostRepository _repository;

  CreatePostProvider(this._repository);

  // 标签相关
  List<PostTagModel> _tags = [];
  bool _isLoadingTags = false;
  String? _tagsErrorMessage;

  List<PostTagModel> get tags => _tags;
  bool get isLoadingTags => _isLoadingTags;
  String? get tagsErrorMessage => _tagsErrorMessage;

  // 表单数据
  PostTagModel? _selectedTag;
  String _title = '';
  String _content = '';

  PostTagModel? get selectedTag => _selectedTag;
  String get title => _title;
  String get content => _content;

  // 提交状态
  bool _isSubmitting = false;
  String? _submitErrorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get submitErrorMessage => _submitErrorMessage;

  // 表单验证
  bool get canSubmit =>
      _selectedTag != null &&
      _title.trim().isNotEmpty &&
      _content.trim().isNotEmpty &&
      !_isSubmitting;

  /// 加载标签列表
  Future<void> loadTags({int? hospitalId}) async {
    _isLoadingTags = true;
    _tagsErrorMessage = null;
    notifyListeners();

    try {
      _tags = await _repository.getAvailableTags(hospitalId: hospitalId);
      _tagsErrorMessage = null;
    } on ApiException catch (e) {
      _tagsErrorMessage = e.message;
      _tags = [];
    } catch (e) {
      _tagsErrorMessage = '加载标签失败';
      _tags = [];
    } finally {
      _isLoadingTags = false;
      notifyListeners();
    }
  }

  /// 选择标签
  void selectTag(PostTagModel? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  /// 更新标题
  void updateTitle(String value) {
    _title = value;
    notifyListeners();
  }

  /// 更新内容
  void updateContent(String value) {
    _content = value;
    notifyListeners();
  }

  /// 将文本内容转换为HTML格式（保留换行）
  String _convertTextToHtml(String text) {
    // 先去除首尾空白
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '<p></p>';
    
    // 转义HTML特殊字符
    final escaped = trimmed
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
    
    // 将换行符转换为 <br> 标签
    final withBreaks = escaped.replaceAll('\n', '<br>');
    
    // 用段落标签包裹
    return '<p>$withBreaks</p>';
  }

  /// 提交帖子
  Future<AnnouncementModel?> submitPost({required int hospitalId}) async {
    if (!canSubmit) return null;

    _isSubmitting = true;
    _submitErrorMessage = null;
    notifyListeners();

    try {
      final contentHtml = _convertTextToHtml(_content);
      
      final request = CreatePostRequest(
        hospitalId: hospitalId,
        tagId: _selectedTag!.id,
        title: _title.trim(),
        contentHtml: contentHtml,
        contentText: _content.trim(),
      );

      final result = await _repository.createPost(request);
      
      // 成功后重置表单
      _selectedTag = null;
      _title = '';
      _content = '';
      _submitErrorMessage = null;
      
      return result;
    } on ApiException catch (e) {
      _submitErrorMessage = e.message;
      return null;
    } catch (e) {
      _submitErrorMessage = '发布失败，请稍后重试';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// 重置表单
  void reset() {
    _selectedTag = null;
    _title = '';
    _content = '';
    _submitErrorMessage = null;
    notifyListeners();
  }
}

