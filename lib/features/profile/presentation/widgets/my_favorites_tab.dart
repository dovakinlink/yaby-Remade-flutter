import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/presentation/pages/project_detail_page.dart';
import 'package:yabai_app/features/profile/providers/my_favorites_provider.dart';

class MyFavoritesTab extends StatefulWidget {
  const MyFavoritesTab({super.key});

  @override
  State<MyFavoritesTab> createState() => _MyFavoritesTabState();
}

class _MyFavoritesTabState extends State<MyFavoritesTab>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  MyFavoritesProvider? _provider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_provider == null) return;

    final provider = _provider!;
    if (!provider.hasNext || provider.isLoadingMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      unawaited(provider.loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // 使用 Provider.of 并设置 listen: false 来获取 provider，避免在滚动监听器中访问 context
    final provider = Provider.of<MyFavoritesProvider>(context, listen: true);
    _provider = provider;
    
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCardBackground
          : Colors.white,
      color: AppColors.brandGreen,
      child: _buildContent(provider),
    );
  }

  Widget _buildContent(MyFavoritesProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isInitialLoading && provider.favorites.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    if (provider.errorMessage != null && provider.favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.refresh(),
                style: ElevatedButton.styleFrom(
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

    if (provider.favorites.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '还没有收藏的项目',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: provider.favorites.length + (provider.hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.favorites.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: provider.isLoadingMore
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }

        final favorite = provider.favorites[index];
        return _buildFavoriteCard(favorite, isDark);
      },
    );
  }

  Widget _buildFavoriteCard(dynamic favorite, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.pushNamed(
              ProjectDetailPage.routeName,
              pathParameters: {'id': favorite.projectId.toString()},
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 项目名称
                Row(
                  children: [
                    if (favorite.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.push_pin,
                          size: 16,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        favorite.projectName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : const Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // 申办方
                if (favorite.sponsorName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 14,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            favorite.sponsorName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 项目进度
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      favorite.progressName,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      favorite.progressText,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // 用户备注
                if (favorite.note != null && favorite.note!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: 14,
                          color: AppColors.brandGreen,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            favorite.note!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 标签
                if (favorite.customTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: favorite.customTags.take(5).map<Widget>((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

