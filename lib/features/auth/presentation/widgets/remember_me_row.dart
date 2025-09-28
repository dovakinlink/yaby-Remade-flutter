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
              Switch(value: value, onChanged: onChanged),
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
                Switch(value: value, onChanged: onChanged),
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
}
