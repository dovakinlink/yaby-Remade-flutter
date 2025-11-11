import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/med_appt/providers/med_appt_create_provider.dart';
import 'package:yabai_app/features/med_appt/utils/date_utils.dart' as med_date_utils;

class MedApptCreatePage extends StatefulWidget {
  const MedApptCreatePage({super.key});

  static const routePath = 'create';
  static const routeName = 'med-appt-create';

  @override
  State<MedApptCreatePage> createState() => _MedApptCreatePageState();
}

class _MedApptCreatePageState extends State<MedApptCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _patientInNoController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _patientNameAbbrController = TextEditingController();
  final _durationController = TextEditingController();
  final _coreValidHoursController = TextEditingController();
  final _drugTextController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<MedApptCreateProvider>();
    _durationController.text = provider.durationMinutes.toString();
    _coreValidHoursController.text = provider.coreValidHours.toString();
  }

  @override
  void dispose() {
    _patientInNoController.dispose();
    _patientNameController.dispose();
    _patientNameAbbrController.dispose();
    _durationController.dispose();
    _coreValidHoursController.dispose();
    _drugTextController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectProject(BuildContext context) async {
    final result = await context.pushNamed('project-selection');
    if (result != null && result is Map<String, dynamic>) {
      final id = result['id'] as int;
      final name = result['name'] as String;
      if (mounted) {
        context.read<MedApptCreateProvider>().setProject(id, name);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final provider = context.read<MedApptCreateProvider>();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: provider.planDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.brandGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      provider.setPlanDate(pickedDate);
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = context.read<MedApptCreateProvider>();

      // 更新所有字段
      provider.setPatientInNo(_patientInNoController.text);
      provider.setPatientName(_patientNameController.text);
      provider.setPatientNameAbbr(_patientNameAbbrController.text);
      provider.setDurationMinutes(int.tryParse(_durationController.text) ?? 120);
      provider.setCoreValidHours(int.tryParse(_coreValidHoursController.text) ?? 0);
      provider.setDrugText(_drugTextController.text);
      provider.setNote(_noteController.text);

      final success = await provider.submit();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('预约创建成功'),
              backgroundColor: AppColors.brandGreen,
            ),
          );
          context.pop(true); // 返回 true 表示成功
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? '创建失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedApptCreateProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('新建预约'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : const Color(0xFFF8F9FA),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 项目选择
            _buildProjectSelector(provider, isDark),
            const SizedBox(height: 16),

            // 患者信息
            _buildSectionTitle('患者信息', isDark),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _patientInNoController,
              label: '患者住院号',
              hint: '请输入患者住院号',
              required: true,
              errorText: provider.fieldErrors['patientInNo'],
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _patientNameController,
              label: '患者姓名',
              hint: '请输入患者姓名',
              required: true,
              errorText: provider.fieldErrors['patientName'],
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _patientNameAbbrController,
              label: '患者姓名简称',
              hint: '例如：张某（可选）',
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // 用药信息
            _buildSectionTitle('用药信息', isDark),
            const SizedBox(height: 12),
            _buildDateSelector(provider, isDark),
            const SizedBox(height: 12),
            _buildTimeSlotSelector(provider, isDark),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _durationController,
                    label: '用药时长（分钟）',
                    hint: '例如：120',
                    required: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: provider.fieldErrors['durationMinutes'],
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _coreValidHoursController,
                    label: '核心药物有效时长（小时）',
                    hint: '例如：24',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _drugTextController,
              label: '具体用药',
              hint: '请输入具体用药内容',
              required: true,
              maxLines: 3,
              errorText: provider.fieldErrors['drugText'],
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _noteController,
              label: '备注',
              hint: '请输入备注信息（可选）',
              maxLines: 3,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // 提交按钮
            FilledButton(
              onPressed: provider.isSubmitting ? null : _handleSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: provider.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      '提交预约',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
      ),
    );
  }

  Widget _buildProjectSelector(MedApptCreateProvider provider, bool isDark) {
    return InkWell(
      onTap: () => _selectProject(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: provider.fieldErrors.containsKey('projectId')
                ? Colors.red
                : (isDark
                    ? AppColors.darkCardBackground
                    : Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.folder_outlined,
              color: provider.projectId != null
                  ? AppColors.brandGreen
                  : (isDark ? AppColors.darkSecondaryText : Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '项目',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.projectName ?? '请选择项目 *',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: provider.projectId != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: provider.projectId != null
                          ? (isDark ? AppColors.darkNeutralText : Colors.grey[800])
                          : (isDark ? AppColors.darkSecondaryText : Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(MedApptCreateProvider provider, bool isDark) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.darkCardBackground
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: AppColors.brandGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '计划用药日期',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    med_date_utils.formatDate(provider.planDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelector(MedApptCreateProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBackground
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '时段 *',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeSlotChip(
                  label: '上午',
                  value: 'AM',
                  selected: provider.timeSlot == 'AM',
                  onTap: () => provider.setTimeSlot('AM'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeSlotChip(
                  label: '下午',
                  value: 'PM',
                  selected: provider.timeSlot == 'PM',
                  onTap: () => provider.setTimeSlot('PM'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeSlotChip(
                  label: '晚上',
                  value: 'EVE',
                  selected: provider.timeSlot == 'EVE',
                  onTap: () => provider.setTimeSlot('EVE'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotChip({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandGreen
              : (isDark
                  ? AppColors.darkScaffoldBackground
                  : Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.brandGreen
                : (isDark
                    ? Colors.grey.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkNeutralText : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkNeutralText : Colors.grey[700],
            ),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(
            color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red
                    : (isDark
                        ? AppColors.darkCardBackground
                        : Colors.grey.withValues(alpha: 0.3)),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red
                    : (isDark
                        ? AppColors.darkCardBackground
                        : Colors.grey.withValues(alpha: 0.3)),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : AppColors.brandGreen,
                width: 2,
              ),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

