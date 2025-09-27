import 'package:flutter/material.dart';

class LoginFormProvider extends ChangeNotifier {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = false;
  bool obscurePassword = true;
  bool isSubmitting = false;

  void toggleRememberMe(bool value) {
    rememberMe = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<void> submit({required Future<void> Function(Map<String, String>) onSubmit}) async {
    if (isSubmitting) return;
    isSubmitting = true;
    notifyListeners();
    try {
      await onSubmit(
        {
          'phone': phoneController.text,
          'password': passwordController.text,
        },
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
