import 'package:flutter/material.dart';
import 'package:yabai_app/features/auth/data/models/auth_tokens.dart';

class AuthSessionProvider extends ChangeNotifier {
  AuthTokens? _tokens;

  AuthTokens? get tokens => _tokens;
  bool get isAuthenticated => _tokens != null;

  void save(AuthTokens tokens) {
    _tokens = tokens;
    notifyListeners();
  }

  void clear() {
    _tokens = null;
    notifyListeners();
  }
}
