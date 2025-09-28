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
  const SearchStatsCard({super.key, required this.stats, this.onSubmitted})
    : assert(stats.length >= 2, 'stats 至少包含两个数据');

  final List<SearchStatItem> stats;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // 统计数据
            Row(
              children: [
                _buildStatItem('入组中', '124'),
                _buildStatItem('待开始', '3'),
                _buildStatItem('停止', '87'),
                _buildStatItem('总数', '214'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
