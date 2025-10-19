import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

/// 备注输入对话框
class RemarkInputDialog extends StatefulWidget {
  const RemarkInputDialog({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<RemarkInputDialog> createState() => _RemarkInputDialogState();
}

class _RemarkInputDialogState extends State<RemarkInputDialog> {
  final _remarkController = TextEditingController();

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final remark = _remarkController.text.trim();
    Navigator.of(context).pop(remark.isEmpty ? null : remark);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(widget.title),
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      content: TextField(
        controller: _remarkController,
        decoration: const InputDecoration(
          labelText: '备注（选填）',
          hintText: '请输入备注信息',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _handleConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
          ),
          child: const Text('确认'),
        ),
      ],
    );
  }
}

