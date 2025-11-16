import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/address_book/presentation/pages/patient_lookup_page.dart';
import 'package:yabai_app/features/address_book/presentation/widgets/address_book_item_card.dart';
import 'package:yabai_app/features/address_book/presentation/widgets/letter_header.dart';
import 'package:yabai_app/features/address_book/presentation/widgets/letter_index_bar.dart';
import 'package:yabai_app/features/address_book/presentation/widgets/search_results_list.dart';
import 'package:yabai_app/features/address_book/providers/address_book_provider.dart';

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key});

  static const routePath = 'address-book';
  static const routeName = 'address-book';

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  Timer? _debounce;

  // 用于记录每个分组的位置
  final Map<String, GlobalKey> _groupKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressBookProvider>().loadAddressBook();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<AddressBookProvider>().search(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<AddressBookProvider>().clearSearch();
  }

  Future<void> _handleRefresh() async {
    await context.read<AddressBookProvider>().refresh();
  }

  void _scrollToLetter(String letter) {
    final provider = context.read<AddressBookProvider>();
    final groupIndex = provider.findGroupIndexByLetter(letter);

    if (groupIndex == null) return;

    // 估算位置并滚动
    // 假设每个标题高度约40，每个卡片高度约72
    double estimatedPosition = 0;
    for (var i = 0; i < groupIndex; i++) {
      final group = provider.groups[i];
      estimatedPosition += 40; // 标题高度
      estimatedPosition += group.itemCount * 72; // 卡片高度
    }

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        estimatedPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToPatientLookup() {
    context.pushNamed(PatientLookupPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AddressBookProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      appBar: AppBar(
        title: const Text('通讯录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: '患者倒查',
            onPressed: _navigateToPatientLookup,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '搜索姓名、手机号',
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : Colors.grey[600],
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : Colors.grey[600],
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkBackground
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                color: isDark
                    ? AppColors.darkNeutralText
                    : Colors.black87,
              ),
            ),
          ),
          // 内容区域
          Expanded(
            child: Stack(
              children: [
                if (provider.isLoading && !provider.isSearchMode)
                  const Center(child: CircularProgressIndicator())
                else if (provider.errorMessage != null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _handleRefresh,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                else if (provider.isSearchMode)
                  provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SearchResultsList(
                          results: provider.searchResults,
                          keyword: provider.searchKeyword,
                        )
                else
                  RefreshIndicator(
                    onRefresh: _handleRefresh,
                    backgroundColor: isDark
                        ? AppColors.darkCardBackground
                        : Colors.white,
                    color: AppColors.brandGreen,
                    child: provider.groups.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.contacts_outlined,
                                  size: 64,
                                  color: isDark
                                      ? AppColors.darkSecondaryText
                                      : Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无通讯录',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 80,
                              right: 52, // 为右侧字母索引留出空间（增大）
                            ),
                            itemCount: provider.groups.fold<int>(
                              0,
                              (count, group) => count + 1 + group.itemCount,
                            ),
                            itemBuilder: (context, index) {
                              var currentIndex = 0;
                              for (var group in provider.groups) {
                                if (index == currentIndex) {
                                  // 显示字母标题
                                  return LetterHeader(letter: group.initial);
                                }
                                currentIndex++;

                                final itemEndIndex = currentIndex + group.itemCount;
                                if (index < itemEndIndex) {
                                  // 显示该组的某个项目
                                  final itemIndex = index - currentIndex;
                                  final item = group.items[itemIndex];
                                  return AddressBookItemCard(item: item);
                                }
                                currentIndex = itemEndIndex;
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                  ),
                // 右侧字母索引（仅在非搜索模式下显示）
                if (!provider.isSearchMode && provider.groups.isNotEmpty)
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: LetterIndexBar(
                        availableLetters: provider.availableLetters,
                        onLetterTap: _scrollToLetter,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

