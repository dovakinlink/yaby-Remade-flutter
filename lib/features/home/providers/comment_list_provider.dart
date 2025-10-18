import 'package:flutter/material.dart';
import 'package:yabai_app/features/home/data/models/comment_model.dart';
import 'package:yabai_app/features/home/data/repositories/comment_repository.dart';

class CommentListProvider extends ChangeNotifier {
  final CommentRepository _repository;
  final int noticeId;

  CommentListProvider(this._repository, {required this.noticeId});

  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _loadMoreError;

  int _currentPage = 0;
  bool _hasNext = false;
  Comment? _replyingTo;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get loadMoreError => _loadMoreError;
  bool get hasNext => _hasNext;
  bool get isEmpty => _comments.isEmpty;
  Comment? get replyingTo => _replyingTo;
  int get commentCount => _comments.length;

  /// 初始加载
  Future<void> loadInitial() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getCommentList(
        noticeId: noticeId,
        page: 1,
        size: 20,
      );
      _comments = response.data;
      _currentPage = response.page;
      _hasNext = response.hasNext;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('加载评论失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext) return;

    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _repository.getCommentList(
        noticeId: noticeId,
        page: nextPage,
        size: 20,
      );
      _comments.addAll(response.data);
      _currentPage = response.page;
      _hasNext = response.hasNext;
      _loadMoreError = null;
    } catch (e) {
      _loadMoreError = e.toString();
      debugPrint('加载更多评论失败: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 刷新
  Future<void> refresh() async {
    _currentPage = 0;
    _hasNext = false;
    _loadMoreError = null;
    await loadInitial();
  }

  /// 创建评论或回复
  Future<bool> createComment(String content) async {
    if (content.trim().isEmpty) {
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      // 创建评论
      await _repository.createComment(
        noticeId: noticeId,
        content: content.trim(),
        replyToCommentId: _replyingTo?.id,
      );
      
      debugPrint('评论创建成功');
      
      // 取消回复状态
      _replyingTo = null;
      
      // 刷新列表（即使刷新失败也不影响评论创建的结果）
      try {
        await refresh();
        debugPrint('评论列表刷新成功');
      } catch (refreshError) {
        debugPrint('评论列表刷新失败（但评论已创建成功）: $refreshError');
      }
      
      return true;
    } catch (e) {
      debugPrint('创建评论失败: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// 删除评论
  Future<bool> deleteComment(int commentId) async {
    try {
      await _repository.deleteComment(commentId);
      
      // 从列表中移除
      _comments.removeWhere((comment) => comment.id == commentId);
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('删除评论失败: $e');
      return false;
    }
  }

  /// 设置正在回复的评论
  void setReplyingTo(Comment comment) {
    _replyingTo = comment;
    notifyListeners();
  }

  /// 取消回复
  void cancelReply() {
    _replyingTo = null;
    notifyListeners();
  }
}

