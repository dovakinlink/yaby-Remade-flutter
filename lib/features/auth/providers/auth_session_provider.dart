import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yabai_app/features/auth/data/models/auth_tokens.dart';

class AuthSessionProvider extends ChangeNotifier {
  static const String _tokensKey = 'auth_tokens';
  
  AuthTokens? _tokens;
  bool _isInitialized = false;

  AuthTokens? get tokens => _tokens;
  bool get isAuthenticated =>
      _tokens != null && !_isTokenExpired(_tokens!.accessToken);
  bool get isInitialized => _isInitialized;

  /// 初始化：从本地存储恢复会话
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokensJson = prefs.getString(_tokensKey);
      
      if (tokensJson != null && tokensJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(tokensJson);
        _tokens = AuthTokens.fromJson(data);

        if (_tokens != null &&
            _isTokenExpired(_tokens!.accessToken)) {
          debugPrint('本地存储的访问令牌已过期，将尝试使用 refresh token 刷新');
        }
      }
    } catch (e) {
      debugPrint('恢复会话失败: $e');
      _tokens = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 保存令牌并持久化
  Future<void> save(AuthTokens tokens) async {
    _tokens = tokens;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokensJson = jsonEncode(tokens.toJson());
      await prefs.setString(_tokensKey, tokensJson);
    } catch (e) {
      debugPrint('保存令牌失败: $e');
    }
  }

  /// 清除令牌并删除持久化数据
  Future<void> clear() async {
    _tokens = null;
    notifyListeners();
    
    try {
      await _removePersistedTokens();
    } catch (e) {
      debugPrint('清除令牌失败: $e');
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return true;
      }

      final payloadSegment = parts[1];
      final padded = base64Url.normalize(payloadSegment);
      final payloadJson =
          utf8.decode(base64Url.decode(padded));
      final dynamic payload = jsonDecode(payloadJson);

      final dynamic expValue = payload is Map<String, dynamic>
          ? payload['exp']
          : null;
      if (expValue is! num) {
        return true;
      }

      final expiry =
          DateTime.fromMillisecondsSinceEpoch(expValue.toInt() * 1000);
      // 设置 5 秒余量，避免刚好过期
      return expiry
          .isBefore(DateTime.now().subtract(const Duration(seconds: 5)));
    } catch (e) {
      debugPrint('解析访问令牌失败: $e');
      return true;
    }
  }

  Future<void> _removePersistedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokensKey);
  }
}
