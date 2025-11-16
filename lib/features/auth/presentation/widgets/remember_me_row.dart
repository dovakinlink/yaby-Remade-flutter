import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

class RememberMeRow extends StatelessWidget {
  const RememberMeRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onForgotPassword,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool allowInlineLink = constraints.maxWidth > 360;
        final Widget link = TextButton(
          onPressed: onForgotPassword,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.centerRight,
            foregroundColor: AppColors.accentBlue,
          ),
          child: const Text('如忘记密码请联系管理员', softWrap: true),
        );

        if (allowInlineLink) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCustomSwitch(value: value, onChanged: onChanged),
              const SizedBox(width: 8),
              const Text('记住我'),
              const Spacer(),
              link,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCustomSwitch(value: value, onChanged: onChanged),
                const SizedBox(width: 8),
                const Text('记住我'),
              ],
            ),
            Align(alignment: Alignment.centerRight, child: link),
          ],
        );
      },
    );
  }

  /// 构建自定义开关，使用品牌绿色，更加明显
  Widget _buildCustomSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      // 使用品牌绿色作为激活状态的颜色，增强视觉对比度
      thumbColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          // 滑块颜色始终为白色，与背景形成对比
          return Colors.white;
        },
      ),
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            // 激活状态：使用品牌绿色
            return AppColors.brandGreen;
          }
          // 未激活状态：使用浅灰色
          return Colors.grey[300]!;
        },
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            // 激活状态：使用品牌绿色边框
            return AppColors.brandGreen;
          }
          // 未激活状态：使用深灰色边框，增强对比度
          return Colors.grey[400]!;
        },
      ),
    );
  }
}
