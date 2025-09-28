import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/auth/data/models/auth_exception.dart';
import 'package:yabai_app/features/auth/data/repositories/auth_repository.dart';
import 'package:yabai_app/features/auth/providers/auth_session_provider.dart';
import 'package:yabai_app/core/widgets/animated_medical_background.dart';
import 'package:yabai_app/core/widgets/labeled_text_field.dart';
import 'package:yabai_app/core/widgets/primary_button.dart';
import 'package:yabai_app/features/auth/providers/login_form_provider.dart';
import 'package:yabai_app/features/auth/presentation/widgets/remember_me_row.dart';
import 'package:yabai_app/features/home/presentation/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const routePath = '/';
  static const routeName = 'login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: AnimatedMedicalBackground(
                baseColor: AppColors.brandGreen,
                density: 1.6,
                showHelix: true,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0, // 固定边距，确保所有设备上一致
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 
                              MediaQuery.of(context).padding.top - 80, // 确保有足够高度进行居中
                  ),
                  child: Center(
                    child: Consumer<LoginFormProvider>(
                      builder: (context, form, _) {
                        return Form(
                          key: _formKey,
                          child: Align(
                            alignment: Alignment.center, // 改为居中对齐，视觉效果更好
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: screenWidth > 600 ? 400 : screenWidth * 0.9, // 大屏幕限制宽度，小屏幕使用百分比
                                minWidth: 280, // 设置合理的最小宽度
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth > 400 ? 32 : 24, // 根据屏幕宽度调整内边距
                                  vertical: 32,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 28,
                                      offset: const Offset(0, 18),
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '登陆',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 28),
                                    LabeledTextField(
                                      label: '手机号',
                                      controller: form.phoneController,
                                      hintText: '请输入您的手机号',
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '请输入手机号';
                                        }
                                        if (value.length < 6) {
                                          return '手机号长度不正确';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    LabeledTextField(
                                      label: '密码',
                                      controller: form.passwordController,
                                      hintText: '请输入密码',
                                      obscureText: form.obscurePassword,
                                      onToggleObscure:
                                          form.togglePasswordVisibility,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '请输入密码';
                                        }
                                        if (value.length < 6) {
                                          return '密码至少 6 位';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    RememberMeRow(
                                      value: form.rememberMe,
                                      onChanged: form.toggleRememberMe,
                                      onForgotPassword: () {},
                                    ),
                                    const SizedBox(height: 32),
                                    PrimaryButton(
                                      label: form.isSubmitting ? '登陆中…' : '登陆',
                                      onPressed: form.isSubmitting
                                          ? null
                                          : () async {
                                              if (!_formKey.currentState!
                                                  .validate()) {
                                                return;
                                              }
                                              FocusScope.of(context).unfocus();
                                              final authRepository = context
                                                  .read<AuthRepository>();
                                              final session = context
                                                  .read<AuthSessionProvider>();

                                              await form.submit(
                                                onSubmit: (payload) async {
                                                  try {
                                                    final tokens =
                                                        await authRepository.signIn(
                                                          username:
                                                              payload['username'] ??
                                                              '',
                                                          password:
                                                              payload['password'] ??
                                                              '',
                                                        );
                                                    session.save(tokens);
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('登陆成功'),
                                                      ),
                                                    );
                                                    context.go(
                                                      HomePage.routePath,
                                                    );
                                                  } on AuthException catch (
                                                    error
                                                  ) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          error.message,
                                                        ),
                                                      ),
                                                    );
                                                  } catch (_) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          '登录失败，请稍后重试',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              );
                                            },
                                    ),
                                    const SizedBox(height: 28),
                                    const Divider(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
