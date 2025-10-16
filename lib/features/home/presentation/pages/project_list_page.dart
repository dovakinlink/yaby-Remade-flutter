import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_card.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_filter_sheet.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_search_bar.dart';
import 'package:yabai_app/features/home/providers/project_list_provider.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  static const routePath = 'projects';
  static const routeName = 'projects';

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    
    // 加载属性定义
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectListProvider>().loadAttrDefinitions();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final provider = context.read<ProjectListProvider>();
    if (!provider.hasNext || provider.isLoadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      unawaited(provider.loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ProjectListProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('临床试验项目'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : const Color(0xFFF8F9FA),
        actions: [
          // 筛选按钮
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _handleFilterTap(provider),
              ),
              if (provider.activeFiltersCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.brandGreen,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${provider.activeFiltersCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ProjectListProvider>().refresh(),
          backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
          color: AppColors.brandGreen,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 搜索栏
              SliverToBoxAdapter(
                child: ProjectSearchBar(
                  initialValue: provider.searchKeyword,
                  onSearch: (keyword) => provider.search(keyword),
                  onCancel: () => provider.clearSearch(),
                  isSearchMode: provider.isSearchMode,
                ),
              ),
              
              // 搜索模式提示
              if (provider.isSearchMode)
                SliverToBoxAdapter(
                  child: _buildSearchModeHeader(provider, isDark),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              
              // 筛选条件 Chips（非搜索模式时显示）
              if (provider.activeFiltersCount > 0 && !provider.isSearchMode)
                SliverToBoxAdapter(
                  child: _buildFilterChips(provider, isDark),
                ),
              
              ..._buildProjectSlivers(provider),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: _buildFooter(provider)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProjectSlivers(ProjectListProvider provider) {
    if (provider.isInitialLoading && provider.projects.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                ),
              ),
            ),
          ),
        ),
      ];
    }

    if (provider.errorMessage != null && provider.projects.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: _ErrorState(
              message: provider.errorMessage!,
              onRetry: provider.refresh,
            ),
          ),
        ),
      ];
    }

    if (provider.projects.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Center(
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
                    provider.isSearchMode
                        ? '没有找到相关项目'
                        : '暂无临床试验项目',
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
            ),
          ),
        ),
      ];
    }

    return [
      SliverList.separated(
        itemBuilder: (context, index) {
          final project = provider.projects[index];
          return ProjectCard(
            project: project,
            onTap: () {
              context.pushNamed(
                'project-detail',
                pathParameters: {'id': '${project.id}'},
              );
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemCount: provider.projects.length,
      ),
    ];
  }

  Widget _buildFooter(ProjectListProvider provider) {
    if (provider.projects.isEmpty) {
      return const SizedBox.shrink();
    }

    if (provider.isLoadingMore) {
      return const SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    if (provider.loadMoreError != null) {
      return Column(
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
      );
    }

    if (!provider.hasNext) {
      return const Text(
        '已经浏览完全部项目',
        style: TextStyle(color: Color(0xFF94A3B8)),
      );
    }

    return const Text(
      '下拉刷新，继续加载更多内容',
      style: TextStyle(color: Color(0xFF94A3B8)),
    );
  }

  Widget _buildSearchModeHeader(ProjectListProvider provider, bool isDark) {
    final totalCount = provider.projects.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkSecondaryText : Colors.grey[700],
                ),
                children: [
                  const TextSpan(text: '搜索 "'),
                  TextSpan(
                    text: provider.searchKeyword,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandGreen,
                    ),
                  ),
                  const TextSpan(text: '" 的结果'),
                ],
              ),
            ),
          ),
          if (!provider.isInitialLoading)
            Text(
              '$totalCount 项',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[700],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ProjectListProvider provider, bool isDark) {
    final filters = provider.selectedFilters.values
        .where((filter) => filter.hasValue)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '筛选条件',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => provider.clearFilters(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '清空',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.brandGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((filter) {
              Map<int, String>? optionLabels;
              try {
                if (filter.dataType == 'option' || 
                    filter.dataType == 'multi_option') {
                  optionLabels = provider.getOptionLabels(filter.attrCode);
                }
              } catch (_) {
                // 忽略错误
              }

              final displayLabel = filter.getDisplayLabel(optionLabels);

              return Chip(
                label: Text(
                  '${filter.attrLabel}: $displayLabel',
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => provider.removeFilter(filter.attrCode),
                backgroundColor: isDark
                    ? AppColors.brandGreen.withValues(alpha: 0.2)
                    : AppColors.brandGreen.withValues(alpha: 0.1),
                labelStyle: const TextStyle(
                  color: AppColors.brandGreen,
                ),
                deleteIconColor: AppColors.brandGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.brandGreen.withValues(alpha: 0.3),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFilterTap(ProjectListProvider provider) async {
    final searchableAttrs = provider.searchableAttrDefinitions;
    
    if (searchableAttrs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂无可用的筛选条件'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final result = await showProjectFilterSheet(
      context,
      attrDefinitions: searchableAttrs,
      currentFilters: provider.selectedFilters,
    );

    if (result != null && mounted) {
      await provider.updateFilters(result);
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          size: 64,
          color: Color(0xFFEF4444),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            onRetry();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('重新加载'),
        ),
      ],
    );
  }
}

