import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/address_book/presentation/widgets/address_book_item_card.dart';
import 'package:yabai_app/features/address_book/providers/patient_lookup_provider.dart';

class PatientLookupPage extends StatefulWidget {
  const PatientLookupPage({super.key});

  static const routePath = 'patient-lookup';
  static const routeName = 'patient-lookup';

  @override
  State<PatientLookupPage> createState() => _PatientLookupPageState();
}

class _PatientLookupPageState extends State<PatientLookupPage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() {
        setState(() {}); // 更新清除按钮的显示状态
      });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入患者姓名或住院号'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    context.read<PatientLookupProvider>().lookup(keyword);
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<PatientLookupProvider>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PatientLookupProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      appBar: AppBar(
        title: const Text('患者倒查CRC'),
      ),
      body: Column(
        children: [
          // 搜索框
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '输入患者姓名或住院号',
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
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _handleSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('查询'),
                ),
              ],
            ),
          ),
          // 结果区域
          Expanded(
            child: _buildContent(provider, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PatientLookupProvider provider, bool isDark) {
    if (!provider.hasResults && provider.errorMessage == null && !provider.isLoading) {
      // 初始状态
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              size: 80,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '输入患者信息查询负责的CRC',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '支持姓名或住院号查询',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (provider.errorMessage != null) {
      // 错误状态
      return Center(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!provider.hasResults) {
      // 无结果
      return Center(
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
              '未找到负责该患者的CRC',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请检查输入是否正确',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // 显示CRC列表（使用标准通讯录卡片）
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: provider.results.length,
      itemBuilder: (context, index) {
        final crc = provider.results[index];
        return AddressBookItemCard(item: crc);
      },
    );
  }
}
