import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/med_appt/data/models/med_appt_model.dart';

class MedApptCard extends StatelessWidget {
  const MedApptCard({
    super.key,
    required this.appointment,
    this.onTap,
  });

  final MedApptModel appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? AppColors.darkCardBackground
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 项目名称和状态
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appointment.projName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkNeutralText : null,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    status: appointment.status,
                    label: appointment.statusLabel,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 患者信息
              _InfoRow(
                icon: Icons.person_outline,
                label: '患者',
                value: '${appointment.patientName} (${appointment.patientInNo})',
                isDark: isDark,
              ),
              const SizedBox(height: 8),

              // 医生信息
              _InfoRow(
                icon: Icons.medical_services_outlined,
                label: '医生',
                value: appointment.researcherName,
                isDark: isDark,
              ),
              const SizedBox(height: 8),

              // 时段和时长
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.access_time,
                      label: '时段',
                      value: appointment.timeSlotLabel,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.timer_outlined,
                      label: '时长',
                      value: '${appointment.durationMinutes}分钟',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 用药内容
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.brandGreen.withValues(alpha: 0.1)
                      : AppColors.brandGreen.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.brandGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 16,
                          color: AppColors.brandGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '用药',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.brandGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appointment.drugText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.darkNeutralText
                                : Colors.grey[800],
                          ),
                    ),
                  ],
                ),
              ),

              // 备注（如有）
              if (appointment.note != null && appointment.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_outlined,
                      size: 16,
                      color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : Colors.grey[600],
                            ),
                      ),
                    ),
                  ],
                ),
              ],

              // CRC和护士信息（如有）
              if (appointment.crcName != null || appointment.nurseName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (appointment.crcName != null) ...[
                      Icon(
                        Icons.support_agent_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'CRC: ${appointment.crcName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : Colors.grey[600],
                              fontSize: 12,
                            ),
                      ),
                    ],
                    if (appointment.crcName != null &&
                        appointment.nurseName != null)
                      const SizedBox(width: 16),
                    if (appointment.nurseName != null) ...[
                      Icon(
                        Icons.local_hospital_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '护士: ${appointment.nurseName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : Colors.grey[600],
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.label,
  });

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'PENDING':
        backgroundColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange[700]!;
        break;
      case 'CONFIRMED':
        backgroundColor = AppColors.brandGreen.withValues(alpha: 0.15);
        textColor = AppColors.brandGreen;
        break;
      case 'CANCELLED':
        backgroundColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red[700]!;
        break;
      case 'DONE':
        backgroundColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue[700]!;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

