import 'package:flutter/material.dart';

class RegisterFormProvider extends ChangeNotifier {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nicknameController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isSubmitting = false;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  Future<void> submit({
    required Future<void> Function(Map<String, String>) onSubmit,
  }) async {
    if (isSubmitting) return;
    isSubmitting = true;
    notifyListeners();
    try {
      await onSubmit({
        'username': usernameController.text,
        'password': passwordController.text,
        'nickname': nicknameController.text,
      });
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }
}
