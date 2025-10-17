import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/widgets/labeled_text_field.dart';
import 'package:yabai_app/core/widgets/primary_button.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/auth/providers/user_profile_provider.dart';

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    try {
      await context.read<UserProfileProvider>().changePassword(
            oldPassword: oldPassword,
            newPassword: newPassword,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('修改密码失败，请稍后重试')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '修改密码',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '为了保护您的账号安全，请输入旧密码并设置一个新的密码。',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : const Color(0xFF6B7280),
                        ),
                  ),
                  const SizedBox(height: 24),
                  LabeledTextField(
                    label: '旧密码',
                    controller: _oldPasswordController,
                    hintText: '请输入旧密码',
                    obscureText: _obscureOldPassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscureOldPassword = !_obscureOldPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入旧密码';
                      }
                      if (value.trim().length < 6) {
                        return '旧密码至少 6 位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  LabeledTextField(
                    label: '新密码',
                    controller: _newPasswordController,
                    hintText: '请输入新密码',
                    obscureText: _obscureNewPassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入新密码';
                      }
                      if (value.trim().length < 6) {
                        return '新密码至少 6 位';
                      }
                      if (value.trim() == _oldPasswordController.text.trim()) {
                        return '新密码不能与旧密码相同';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: _isSubmitting ? '提交中…' : '确认修改',
                    onPressed: _isSubmitting ? null : _handleSubmit,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).maybePop(),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: AppColors.brandGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
