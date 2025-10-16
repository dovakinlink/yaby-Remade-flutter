import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/attr_definition_model.dart';
import 'package:yabai_app/features/home/data/models/filter_value_model.dart';
import 'package:yabai_app/features/home/presentation/widgets/filter_item_widget.dart';

class ProjectFilterSheet extends StatefulWidget {
  const ProjectFilterSheet({
    super.key,
    required this.attrDefinitions,
    required this.currentFilters,
  });

  final List<AttrDefinitionModel> attrDefinitions;
  final Map<String, FilterValueModel> currentFilters;

  @override
  State<ProjectFilterSheet> createState() => _ProjectFilterSheetState();
}

class _ProjectFilterSheetState extends State<ProjectFilterSheet> {
  late Map<String, dynamic> _tempValues;

  @override
  void initState() {
    super.initState();
    // 初始化临时值
    _tempValues = {};
    for (final filter in widget.currentFilters.values) {
      _tempValues[filter.attrCode] = filter.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部栏
          _buildHeader(isDark),
          const Divider(height: 1),
          // 筛选项列表
          Flexible(
            child: _buildFilterList(isDark),
          ),
          // 底部操作栏
          _buildActions(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Text(
            '筛选条件',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _handleReset,
            child: Text(
              '重置',
              style: TextStyle(
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[700],
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterList(bool isDark) {
    if (widget.attrDefinitions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Text(
            '暂无可用的筛选条件',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: widget.attrDefinitions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final attr = widget.attrDefinitions[index];
        return FilterItemWidget(
          attr: attr,
          value: _tempValues[attr.code],
          onChanged: (value) {
            setState(() {
              _tempValues[attr.code] = value;
            });
          },
        );
      },
    );
  }

  Widget _buildActions(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDividerColor : AppColors.lightDividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: isDark ? AppColors.darkFieldBorder : AppColors.lightFieldBorder,
                ),
              ),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _handleConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('确定'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleReset() {
    setState(() {
      _tempValues.clear();
    });
  }

  void _handleConfirm() {
    // 构建筛选条件
    final filters = <String, FilterValueModel>{};
    
    for (final attr in widget.attrDefinitions) {
      final value = _tempValues[attr.code];
      if (value != null) {
        // 检查值是否有效
        bool hasValidValue = false;
        if (value is String && value.trim().isNotEmpty) {
          hasValidValue = true;
        } else if (value is List && value.isNotEmpty) {
          hasValidValue = true;
        } else if (value is! String && value is! List) {
          hasValidValue = true;
        }

        if (hasValidValue) {
          filters[attr.code] = FilterValueModel(
            attrCode: attr.code,
            attrLabel: attr.label,
            dataType: attr.dataType,
            value: value,
          );
        }
      }
    }

    Navigator.of(context).pop(filters);
  }
}

/// 显示筛选底部抽屉
Future<Map<String, FilterValueModel>?> showProjectFilterSheet(
  BuildContext context, {
  required List<AttrDefinitionModel> attrDefinitions,
  required Map<String, FilterValueModel> currentFilters,
}) {
  return showModalBottomSheet<Map<String, FilterValueModel>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProjectFilterSheet(
      attrDefinitions: attrDefinitions,
      currentFilters: currentFilters,
    ),
  );
}

