import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_attrs_section.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_basic_info_section.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_criteria_section.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_files_section.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_staff_section.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_tags_section.dart';
import 'package:yabai_app/features/home/providers/project_detail_provider.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  static const routePath = ':id';
  static const routeName = 'project-detail';

  final int projectId;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectDetailProvider>().loadDetail(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ProjectDetailProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(provider.project?.projName ?? '项目详情'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : const Color(0xFFF8F9FA),
      ),
      body: _buildBody(provider, isDark),
    );
  }

  Widget _buildBody(ProjectDetailProvider provider, bool isDark) {
    if (provider.isLoading && provider.project == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    if (provider.errorMessage != null && provider.project == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  provider.loadDetail(widget.projectId);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.project == null) {
      return const Center(
        child: Text('项目不存在'),
      );
    }

    final project = provider.project!;

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      color: AppColors.brandGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              color:
                  isDark ? AppColors.darkCardBackground : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 基本信息
                  ProjectBasicInfoSection(
                    project: project,
                    showTopDivider: false,
                  ),
                  // 自定义属性
                  if (project.hasCustomAttrs)
                    ProjectAttrsSection(attrs: project.customAttrs),
                  // 标签
                  if (project.hasCustomTags)
                    ProjectTagsSection(tags: project.customTags),
                  // 入排标准
                  if (project.hasCriteria)
                    ProjectCriteriaSection(criteria: project.criteria),
                  // 附件
                  if (project.hasFiles)
                    ProjectFilesSection(files: project.files),
                  // 人员
                  if (project.hasStaff)
                    ProjectStaffSection(staff: project.staff),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
