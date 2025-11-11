import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/med_appt/data/models/med_appt_model.dart';

/// 用药预约操作对话框
class MedApptActionDialog extends StatelessWidget {
  const MedApptActionDialog({
    super.key,
    required this.appointment,
  });

  final MedApptModel appointment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        '预约详情',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkNeutralText : Colors.grey[900],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(
              '项目',
              appointment.projName,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              '患者',
              '${appointment.patientName} (${appointment.patientInNo})',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              '医生',
              appointment.researcherName,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              '时段',
              appointment.timeSlotLabel,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              '时长',
              '${appointment.durationMinutes}分钟',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              '状态',
              appointment.statusLabel,
              isDark,
              valueColor: _getStatusColor(appointment.status),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.brandGreen.withValues(alpha: 0.1)
                    : AppColors.brandGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '用药',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.brandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appointment.drugText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            if (appointment.note != null && appointment.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                '备注',
                appointment.note!,
                isDark,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '关闭',
            style: TextStyle(
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
          ),
        ),
        if (appointment.status == 'PENDING') ...[
          FilledButton(
            onPressed: () => Navigator.of(context).pop('confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认预约'),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ??
                  (isDark ? AppColors.darkNeutralText : Colors.grey[900]),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange[700]!;
      case 'CONFIRMED':
        return AppColors.brandGreen;
      case 'CANCELLED':
        return Colors.red[700]!;
      case 'DONE':
        return Colors.blue[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}

/// 显示预约操作对话框
Future<String?> showMedApptActionDialog(
  BuildContext context,
  MedApptModel appointment,
) {
  return showDialog<String>(
    context: context,
    builder: (context) => MedApptActionDialog(appointment: appointment),
  );
}

