import 'package:flutter/material.dart';
import 'package:yabai_app/features/address_book/data/models/address_book_group_model.dart';
import 'package:yabai_app/features/address_book/data/models/address_book_item_model.dart';
import 'package:yabai_app/features/address_book/data/repositories/address_book_repository.dart';

class AddressBookProvider extends ChangeNotifier {
  AddressBookProvider(this._repository);

  final AddressBookRepository _repository;

  List<AddressBookGroupModel> _groups = [];
  List<AddressBookItemModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearchMode = false;
  String? _errorMessage;
  String _searchKeyword = '';

  List<AddressBookGroupModel> get groups => _groups;
  List<AddressBookItemModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearchMode => _isSearchMode;
  String? get errorMessage => _errorMessage;
  String get searchKeyword => _searchKeyword;

  /// 加载通讯录列表
  Future<void> loadAddressBook() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await _repository.fetchAddressBook();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _groups = [];
      debugPrint('加载通讯录失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 搜索通讯录
  Future<void> search(String keyword) async {
    _searchKeyword = keyword;
    
    if (keyword.trim().isEmpty) {
      _isSearchMode = false;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearchMode = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _repository.searchAddressBook(keyword.trim());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _searchResults = [];
      debugPrint('搜索通讯录失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清除搜索
  void clearSearch() {
    _searchKeyword = '';
    _isSearchMode = false;
    _searchResults = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// 刷新通讯录
  Future<void> refresh() async {
    if (_isSearchMode && _searchKeyword.isNotEmpty) {
      await search(_searchKeyword);
    } else {
      await loadAddressBook();
    }
  }

  /// 获取所有可用的字母索引
  List<String> get availableLetters {
    return _groups.map((group) => group.initial).toList();
  }

  /// 根据字母查找分组索引
  int? findGroupIndexByLetter(String letter) {
    for (var i = 0; i < _groups.length; i++) {
      if (_groups[i].initial == letter) {
        return i;
      }
    }
    return null;
  }
}

