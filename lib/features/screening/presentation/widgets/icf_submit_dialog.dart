import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/screening/data/models/icf_request_model.dart';

/// ICF（知情同意）提交对话框
class IcfSubmitDialog extends StatefulWidget {
  const IcfSubmitDialog({super.key});

  @override
  State<IcfSubmitDialog> createState() => _IcfSubmitDialogState();
}

class _IcfSubmitDialogState extends State<IcfSubmitDialog> {
  final _icfVersionController = TextEditingController();
  final _signerNameController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _icfVersionController.dispose();
    _signerNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _handleSubmit() {
    if (_icfVersionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入ICF版本')),
      );
      return;
    }

    if (_signerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入签署人姓名')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择签署日期')),
      );
      return;
    }

    final request = IcfRequestModel(
      icfVersion: _icfVersionController.text.trim(),
      icfDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      signerName: _signerNameController.text.trim(),
    );

    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('提交知情同意'),
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _icfVersionController,
              decoration: const InputDecoration(
                labelText: 'ICF版本',
                hintText: '例如：V1.2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _signerNameController,
              decoration: const InputDecoration(
                labelText: '签署人姓名',
                hintText: '请输入签署人姓名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDate == null
                    ? '选择签署日期'
                    : '签署日期：${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
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

