import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/home/data/models/share_link_model.dart';
import 'package:yabai_app/features/home/data/repositories/project_repository.dart';

/// 项目分享链接状态管理
class ShareLinkProvider with ChangeNotifier {
  ShareLinkProvider(this._repository);

  final ProjectRepository _repository;

  bool _isLoading = false;
  ShareLinkModel? _shareLink;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  ShareLinkModel? get shareLink => _shareLink;
  String? get errorMessage => _errorMessage;

  /// 生成项目分享链接
  Future<ShareLinkModel?> generateShareLink(int projectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _shareLink = await _repository.generateShareLink(projectId);
      _isLoading = false;
      notifyListeners();
      return _shareLink;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = '生成分享链接失败: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 清除分享链接数据
  void clearShareLink() {
    _shareLink = null;
    _errorMessage = null;
    notifyListeners();
  }
}

