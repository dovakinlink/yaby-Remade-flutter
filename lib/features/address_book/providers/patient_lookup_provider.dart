import 'package:flutter/material.dart';
import 'package:yabai_app/features/address_book/data/models/address_book_item_model.dart';
import 'package:yabai_app/features/address_book/data/repositories/address_book_repository.dart';

class PatientLookupProvider extends ChangeNotifier {
  PatientLookupProvider(this._repository);

  final AddressBookRepository _repository;

  List<AddressBookItemModel> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _lastKeyword = '';

  List<AddressBookItemModel> get results => _results;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get lastKeyword => _lastKeyword;
  bool get hasResults => _results.isNotEmpty;

  /// 执行倒查
  Future<void> lookup(String keyword) async {
    if (keyword.trim().isEmpty) {
      _errorMessage = '请输入患者姓名或住院号';
      notifyListeners();
      return;
    }

    _lastKeyword = keyword;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _results = await _repository.lookupCrcByPatient(keyword.trim());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _results = [];
      debugPrint('患者倒查失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清空结果
  void clear() {
    _results = [];
    _errorMessage = null;
    _lastKeyword = '';
    notifyListeners();
  }
}

