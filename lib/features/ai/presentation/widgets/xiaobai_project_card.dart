import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/models/xiaobai_patient_project_model.dart';

class XiaobaiProjectCard extends StatelessWidget {
  const XiaobaiProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.isSelected = false,
  });

  final XiaobaiPatientProject project;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAvailable = project.xiaobaiStatus == 1;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? AppColors.brandGreen 
              : (isDark ? AppColors.darkDividerColor : Colors.grey[200]!),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: isAvailable ? 1.0 : 0.6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.projectName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkNeutralText : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '已选',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '未上传',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : Colors.grey[400],
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.shortTitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : Colors.grey[600],
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

