import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

class SearchStatItem {
  const SearchStatItem({
    required this.label,
    required this.value,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;
}

class SearchStatsCard extends StatelessWidget {
  const SearchStatsCard({
    super.key,
    required this.stats,
    this.onSubmitted,
    this.onTap,
  }) : assert(stats.length >= 2, 'stats 至少包含两个数据');

  final List<SearchStatItem> stats;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.brandGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // 搜索框
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '食管癌一线治疗有合适的临床项目吗？',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                    Icon(Icons.search, color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 统计数据
              Row(
                children: stats
                    .map((item) => _buildStatItem(item))
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(SearchStatItem item) {
    return Expanded(
      child: Column(
        children: [
          Text(
            item.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.caption != null) ...[
            const SizedBox(height: 6),
            Text(
              item.caption!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
