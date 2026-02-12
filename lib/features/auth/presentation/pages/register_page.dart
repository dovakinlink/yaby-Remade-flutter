import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/config/env_config.dart';
import 'package:yabai_app/core/constants/legal_urls.dart';
import 'package:yabai_app/features/auth/data/models/auth_exception.dart';
import 'package:yabai_app/features/auth/data/repositories/auth_repository.dart';
import 'package:yabai_app/core/widgets/animated_medical_background.dart';
import 'package:yabai_app/core/widgets/labeled_text_field.dart';
import 'package:yabai_app/core/widgets/primary_button.dart';
import 'package:yabai_app/features/auth/providers/register_form_provider.dart';
import 'package:yabai_app/features/auth/presentation/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static const routePath = '/register';
  static const routeName = 'register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  // 协议勾选状态
  bool _agreedPrivacyPolicy = false;
  bool _agreedUserAgreement = false;

  /// 打开URL
  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('打开URL失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
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
                    horizontal: 32,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          80,
                    ),
                    child: Center(
                      child: ChangeNotifierProvider(
                        create: (_) => RegisterFormProvider(),
                        child: Consumer<RegisterFormProvider>(
                          builder: (context, form, _) {
                            return Form(
                              key: _formKey,
                              child: Align(
                                alignment: Alignment.center,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        screenWidth > 600 ? 400 : screenWidth * 0.9,
                                    minWidth: 280,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth > 400 ? 32 : 24,
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
                                          '注册',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 28),
                                        LabeledTextField(
                                          label: '用户名',
                                          controller: form.usernameController,
                                          hintText: '请输入用户名（4-50字符）',
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return '请输入用户名';
                                            }
                                            if (value.length < 4) {
                                              return '用户名至少 4 个字符';
                                            }
                                            if (value.length > 50) {
                                              return '用户名不能超过 50 个字符';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        LabeledTextField(
                                          label: '密码',
                                          controller: form.passwordController,
                                          hintText: '请输入密码（6-100字符）',
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
                                            if (value.length > 100) {
                                              return '密码不能超过 100 位';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        LabeledTextField(
                                          label: '确认密码',
                                          controller: form.confirmPasswordController,
                                          hintText: '请再次输入密码',
                                          obscureText: form.obscureConfirmPassword,
                                          onToggleObscure:
                                              form.toggleConfirmPasswordVisibility,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return '请确认密码';
                                            }
                                            if (value != form.passwordController.text) {
                                              return '两次输入的密码不一致';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        LabeledTextField(
                                          label: '昵称（可选）',
                                          controller: form.nicknameController,
                                          hintText: '请输入昵称',
                                          validator: (value) {
                                            if (value != null && value.length > 50) {
                                              return '昵称不能超过 50 个字符';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                        // 隐私政策勾选
                                        _buildAgreementCheckbox(
                                          value: _agreedPrivacyPolicy,
                                          onChanged: (value) {
                                            setState(() {
                                              _agreedPrivacyPolicy = value ?? false;
                                            });
                                          },
                                          label: '隐私政策',
                                          url: LegalUrls.privacyPolicy,
                                        ),
                                        const SizedBox(height: 8),
                                        // 用户协议勾选
                                        _buildAgreementCheckbox(
                                          value: _agreedUserAgreement,
                                          onChanged: (value) {
                                            setState(() {
                                              _agreedUserAgreement = value ?? false;
                                            });
                                          },
                                          label: '用户协议',
                                          url: LegalUrls.userAgreement,
                                        ),
                                        const SizedBox(height: 24),
                                        PrimaryButton(
                                          label: form.isSubmitting ? '注册中…' : '注册',
                                          onPressed: form.isSubmitting
                                              ? null
                                              : () async {
                                                  if (!_formKey.currentState!
                                                      .validate()) {
                                                    return;
                                                  }
                                                  // 验证是否同意协议
                                                  if (!_agreedPrivacyPolicy || !_agreedUserAgreement) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('请同意隐私政策和用户协议'),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  FocusScope.of(context).unfocus();
                                                  final authRepository =
                                                      context.read<AuthRepository>();

                                                  await form.submit(
                                                    onSubmit: (payload) async {
                                                      try {
                                                        // 调用注册接口
                                                        await authRepository.signUp(
                                                          username:
                                                              payload['username'] ??
                                                              '',
                                                          password:
                                                              payload['password'] ??
                                                              '',
                                                          nickname: payload['nickname']?.isNotEmpty == true
                                                              ? payload['nickname']
                                                              : null,
                                                        );
                                                        
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        
                                                        // 显示注册成功提示
                                                        ScaffoldMessenger.of(context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                            content: Text('注册成功！'),
                                                            backgroundColor: Colors.green,
                                                          ),
                                                        );
                                                        
                                                        // 延迟一下再跳转，让用户看到成功提示
                                                        await Future.delayed(
                                                          const Duration(milliseconds: 500),
                                                        );
                                                        
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        
                                                        // 跳转到登录页面
                                                        context.go(LoginPage.routePath);
                                                      } on AuthException catch (error) {
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        ScaffoldMessenger.of(context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(error.message),
                                                          ),
                                                        );
                                                      } catch (_) {
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        ScaffoldMessenger.of(context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                            content: Text('注册失败，请稍后重试'),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '已有账号？',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                context.go(LoginPage.routePath);
                                              },
                                              child: const Text(
                                                '立即登录',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建协议勾选组件
  Widget _buildAgreementCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    required String url,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.brandGreen,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '我已阅读并同意',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              GestureDetector(
                onTap: () => _openUrl(url),
                child: Text(
                  '《$label》',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
