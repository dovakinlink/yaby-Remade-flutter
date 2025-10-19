import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/screening/data/models/enrollment_request_model.dart';

/// 入组信息提交对话框
class EnrollmentSubmitDialog extends StatefulWidget {
  const EnrollmentSubmitDialog({super.key});

  @override
  State<EnrollmentSubmitDialog> createState() => _EnrollmentSubmitDialogState();
}

class _EnrollmentSubmitDialogState extends State<EnrollmentSubmitDialog> {
  final _enrollNoController = TextEditingController();
  DateTime? _enrollDate;
  DateTime? _firstDoseDate;

  @override
  void dispose() {
    _enrollNoController.dispose();
    super.dispose();
  }

  Future<void> _selectEnrollDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _enrollDate = pickedDate;
      });
    }
  }

  Future<void> _selectFirstDoseDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _enrollDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _firstDoseDate = pickedDate;
      });
    }
  }

  void _handleSubmit() {
    if (_enrollNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入入组号')),
      );
      return;
    }

    if (_enrollDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择入组日期')),
      );
      return;
    }

    final request = EnrollmentRequestModel(
      enrollNo: _enrollNoController.text.trim(),
      enrollDate: DateFormat('yyyy-MM-dd').format(_enrollDate!),
      firstDoseDate: _firstDoseDate != null
          ? DateFormat('yyyy-MM-dd').format(_firstDoseDate!)
          : null,
    );

    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('提交入组信息'),
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _enrollNoController,
              decoration: const InputDecoration(
                labelText: '入组号/随机号',
                hintText: '例如：2025-001-001',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _selectEnrollDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _enrollDate == null
                    ? '选择入组日期'
                    : '入组日期：${DateFormat('yyyy-MM-dd').format(_enrollDate!)}',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _selectFirstDoseDate(context),
              icon: const Icon(Icons.medical_services),
              label: Text(
                _firstDoseDate == null
                    ? '选择首次用药日期（可选）'
                    : '首次用药：${DateFormat('yyyy-MM-dd').format(_firstDoseDate!)}',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _handleSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
          ),
          child: const Text('提交'),
        ),
      ],
    );
  }
}

