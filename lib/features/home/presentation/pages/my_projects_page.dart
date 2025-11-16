import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/presentation/pages/project_detail_page.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_card.dart';
import 'package:yabai_app/features/home/providers/project_list_by_person_provider.dart';

class MyProjectsPage extends StatefulWidget {
  const MyProjectsPage({super.key});

  static const routePath = 'my-projects';
  static const routeName = 'my-projects';

  @override
  State<MyProjectsPage> createState() => _MyProjectsPageState();
}

class _MyProjectsPageState extends State<MyProjectsPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    
    // 加载项目列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectListByPersonProvider>().loadInitial();
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

    final provider = context.read<ProjectListByPersonProvider>();
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
    final provider = context.watch<ProjectListByPersonProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('我的项目'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : const Color(0xFFF8F9FA),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ProjectListByPersonProvider>().refresh(),
          backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
          color: AppColors.brandGreen,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              
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

  List<Widget> _buildProjectSlivers(ProjectListByPersonProvider provider) {
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
                  const Icon(
                    Icons.folder_open_outlined,
                    size: 64,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '您暂未参与任何项目',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 16,
                    ),
                  ),
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
                ProjectDetailPage.routeName,
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

  Widget _buildFooter(ProjectListByPersonProvider provider) {
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

