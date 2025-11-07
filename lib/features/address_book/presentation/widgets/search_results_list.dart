import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/address_book/data/models/address_book_item_model.dart';
import 'package:yabai_app/features/address_book/presentation/widgets/address_book_item_card.dart';

class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.results,
    required this.keyword,
  });

  final List<AddressBookItemModel> results;
  final String keyword;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '未找到相关联系人',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '请尝试其他关键词',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return AddressBookItemCard(item: item);
      },
    );
  }
}

