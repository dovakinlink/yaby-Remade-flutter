import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/med_appt/providers/project_selection_provider.dart';
import 'package:yabai_app/features/home/data/models/project_model.dart';

class ProjectSelectionPage extends StatefulWidget {
  const ProjectSelectionPage({super.key});

  static const routePath = 'select-project';
  static const routeName = 'project-selection';

  @override
  State<ProjectSelectionPage> createState() => _ProjectSelectionPageState();
}

class _ProjectSelectionPageState extends State<ProjectSelectionPage> {
  late final ScrollController _scrollController;
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);

    // 初始加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectSelectionProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final provider = context.read<ProjectSelectionProvider>();
    if (!provider.hasNext || provider.isLoadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      unawaited(provider.loadMore());
    }
  }

  void _handleSearch(String keyword) {
    // 防抖：500ms后才执行搜索
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<ProjectSelectionProvider>().search(keyword);
    });
  }

  void _handleClearSearch() {
    _searchController.clear();
    context.read<ProjectSelectionProvider>().clearSearch();
  }

  void _handleProjectSelected(ProjectModel project) {
    context.pop({
      'id': project.id,
      'name': project.projName,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ProjectSelectionProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('选择项目'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : const Color(0xFFF8F9FA),
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              style: TextStyle(
                color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
              ),
              decoration: InputDecoration(
                hintText: '搜索项目名称',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                ),
                suffixIcon: provider.isSearchMode
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : Colors.grey[600],
                        ),
                        onPressed: _handleClearSearch,
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkCardBackground
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkCardBackground
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.brandGreen,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // 项目列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.refresh(),
              backgroundColor:
                  isDark ? AppColors.darkCardBackground : Colors.white,
              color: AppColors.brandGreen,
              child: _buildProjectList(provider, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(ProjectSelectionProvider provider, bool isDark) {
    if (provider.isInitialLoading && provider.projects.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
          ),
        ),
      );
    }

    if (provider.errorMessage != null && provider.projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                onPressed: provider.refresh,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              provider.isSearchMode
                  ? Icons.search_off
                  : Icons.folder_open_outlined,
              size: 64,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              provider.isSearchMode ? '没有找到相关项目' : '暂无项目',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
              ),
            ),
            if (provider.isSearchMode) ...[
              const SizedBox(height: 8),
              Text(
                '试试其他关键词',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.projects.length + 1,
      itemBuilder: (context, index) {
        if (index == provider.projects.length) {
          return _buildFooter(provider);
        }

        final project = provider.projects[index];
        return _ProjectCard(
          project: project,
          onTap: () => _handleProjectSelected(project),
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildFooter(ProjectSelectionProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
            ),
          ),
        ),
      );
    }

    if (provider.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.loadMoreError!,
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                provider.loadMore();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandGreen,
              ),
              child: const Text('重试加载'),
            ),
          ],
        ),
      );
    }

    if (!provider.hasNext) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          '已经浏览完全部项目',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.isDark,
  });

  final ProjectModel project;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.projName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkNeutralText : null,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : Colors.grey[400],
                  ),
                ],
              ),
              if (project.piName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PI: ${project.piName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
              if (project.indication != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 16,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        project.indication!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : Colors.grey[600],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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

