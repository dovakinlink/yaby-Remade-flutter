import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/widgets/animated_medical_background.dart';
import 'package:yabai_app/core/widgets/app_logo.dart';
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
    final padding = MediaQuery.of(context).size.width > 420 ? 120.0 : 24.0;

    return Scaffold(
      body: Stack(
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
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 32),
              child: Center(
                child: Consumer<LoginFormProvider>(
                  builder: (context, form, _) {
                    return Form(
                      key: _formKey,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  AppLogo(size: 72),
                                ],
                              ),
                              const SizedBox(height: 36),
                              Text(
                                '登陆',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
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
                                onToggleObscure: form.togglePasswordVisibility,
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
                                        if (!_formKey.currentState!.validate()) {
                                          return;
                                        }
                                        await form.submit(
                                          onSubmit: (payload) async {
                                            final apiClient = context.read<ApiClient>();
                                            debugPrint(
                                              '使用接口: ${apiClient.dio.options.baseUrl}/login',
                                            );
                                            await Future<void>.delayed(const Duration(milliseconds: 600));
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('登陆成功（演示）')),
                                              );
                                              context.go(HomePage.routePath);
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
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
