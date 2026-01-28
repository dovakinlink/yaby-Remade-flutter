import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.textStyle});

  final double size;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = textStyle ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size / 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/logo.svg',
            width: size * 0.6,
            height: size * 0.6,
          ),
        ),
        const SizedBox(width: 20),
        Text('友研', style: effectiveStyle),
      ],
    );
  }
}
