import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';
import 'package:yabai_app/features/ai/presentation/pages/ai_page.dart';
import 'package:yabai_app/features/ai/presentation/pages/ai_session_detail_page.dart';
import 'package:yabai_app/features/ai/presentation/widgets/ai_session_card.dart';
import 'package:yabai_app/features/ai/providers/ai_query_provider.dart';
import 'package:yabai_app/features/ai/providers/ai_session_list_provider.dart';

class AiSessionListPage extends StatefulWidget {
  const AiSessionListPage({super.key});

  @override
  State<AiSessionListPage> createState() => _AiSessionListPageState();
}

class _AiSessionListPageState extends State<AiSessionListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiSessionListProvider>().loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AiSessionListProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffoldBackground : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: Consumer<AiSessionListProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return _buildErrorState(provider.errorMessage!, isDark);
                  }

                  if (!provider.hasSessions) {
                    return _buildEmptyState(isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: provider.refresh,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.sessions.length + (provider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.sessions.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final session = provider.sessions[index];
                        return AiSessionCard(
                          session: session,
                          onTap: () => _openSessionDetail(context, session.sessionId),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildNewQueryButton(context),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Stack(
              children: [
                Positioned(
                  left: 4,
                  top: 8,
                  bottom: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? AppColors.darkNeutralText : Colors.black87,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Center(
                  child: Text(
                    'AI 对话历史',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkNeutralText : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkDividerColor : Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有 AI 对话记录',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮开始新的查询',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.redAccent : Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkNeutralText : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<AiSessionListProvider>().refresh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildNewQueryButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openNewQuery(context),
      backgroundColor: AppColors.brandGreen,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        '新建查询',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _openNewQuery(BuildContext context) {
    final repository = context.read<AiRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AiQueryProvider(repository),
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkScaffoldBackground
                : const Color(0xFFF8F9FA),
            body: SafeArea(
              top: false,
              bottom: false,
              child: AiPage(
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      // 返回后刷新会话列表
      context.read<AiSessionListProvider>().refresh();
    });
  }

  void _openSessionDetail(BuildContext context, String sessionId) {
    final repository = context.read<AiRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Provider<AiRepository>.value(
          value: repository,
          child: AiSessionDetailPage(sessionId: sessionId),
        ),
      ),
    );
  }
}

