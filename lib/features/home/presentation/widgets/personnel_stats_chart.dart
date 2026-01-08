import 'dart:math';

import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

class PersonnelStat {
  const PersonnelStat(this.role, this.count);

  final String role;
  final int count;
}

class PersonnelStatsChart extends StatelessWidget {
  const PersonnelStatsChart({super.key, this.data = _defaultData});

  final List<PersonnelStat> data;

  static const List<PersonnelStat> _defaultData = [
    PersonnelStat('CRC', 12),
    PersonnelStat('PI', 8),
    PersonnelStat('Sub-I', 10),
    PersonnelStat('CRA', 6),
    PersonnelStat('质控员', 5),
    PersonnelStat('治疗评估员', 4),
    PersonnelStat('护士', 9),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark ? AppColors.darkDividerColor : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '人员统计',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, 220),
                    painter: _PersonnelStatsPainter(
                      data: data,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonnelStatsPainter extends CustomPainter {
  _PersonnelStatsPainter({
    required this.data,
    required this.isDark,
  });

  final List<PersonnelStat> data;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const leftPadding = 36.0;
    const rightPadding = 12.0;
    const topPadding = 12.0;
    const bottomPadding = 38.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final maxValue =
        data.map((item) => item.count).reduce(max).clamp(0, 999999);
    const tickCount = 4;
    final tickStep = max(1, (maxValue / tickCount).ceil());
    final scaledMax = tickStep * tickCount;

    final axisColor =
        isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB);
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    final labelStyle = TextStyle(
      color: isDark ? AppColors.darkSecondaryText : const Color(0xFF6B7280),
      fontSize: 11,
    );

    final origin = Offset(leftPadding, topPadding + chartHeight);
    canvas.drawLine(origin, Offset(leftPadding, topPadding), axisPaint);
    canvas.drawLine(
      origin,
      Offset(leftPadding + chartWidth, topPadding + chartHeight),
      axisPaint,
    );

    for (int i = 0; i <= tickCount; i++) {
      final y = topPadding + chartHeight - (chartHeight / tickCount) * i;
      canvas.drawLine(
        Offset(leftPadding - 4, y),
        Offset(leftPadding, y),
        axisPaint,
      );
      final labelText = (tickStep * i).toString();
      final textPainter = TextPainter(
        text: TextSpan(text: labelText, style: labelStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: leftPadding - 8);
      textPainter.paint(
        canvas,
        Offset(leftPadding - 8 - textPainter.width, y - textPainter.height / 2),
      );
    }

    final barColor = AppColors.brandGreen;
    final barPaint = Paint()..color = barColor;
    final barSpacing = chartWidth / data.length;
    final barWidth = barSpacing * 0.6;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final xCenter = leftPadding + barSpacing * (i + 0.5);
      final barLeft = xCenter - barWidth / 2;
      final barHeight = chartHeight * (item.count / scaledMax);
      final barTop = origin.dy - barHeight;
      final rect = Rect.fromLTWH(barLeft, barTop, barWidth, barHeight);
      canvas.drawRect(rect, barPaint);

      final valuePainter = TextPainter(
        text: TextSpan(
          text: item.count.toString(),
          style: labelStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth + 8);
      valuePainter.paint(
        canvas,
        Offset(xCenter - valuePainter.width / 2, barTop - valuePainter.height - 4),
      );

      final rolePainter = TextPainter(
        text: TextSpan(text: item.role, style: labelStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: barSpacing);
      rolePainter.paint(
        canvas,
        Offset(
          xCenter - rolePainter.width / 2,
          origin.dy + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PersonnelStatsPainter oldDelegate) {
    if (oldDelegate.isDark != isDark ||
        oldDelegate.data.length != data.length) {
      return true;
    }
    for (int i = 0; i < data.length; i++) {
      final oldItem = oldDelegate.data[i];
      final newItem = data[i];
      if (oldItem.role != newItem.role || oldItem.count != newItem.count) {
        return true;
      }
    }
    return false;
  }
}
