import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/post_tag_model.dart';
import 'package:yabai_app/features/home/providers/create_post_provider.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  static const routePath = '/home/create-post';
  static const routeName = 'create-post';

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  // 临时使用固定的 hospitalId，实际应从用户会话中获取
  final int _hospitalId = 1;

  @override
  void initState() {
    super.initState();
    // 加载标签列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreatePostProvider>().loadTags(hospitalId: _hospitalId);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final provider = context.read<CreatePostProvider>();
    
    final result = await provider.submitPost(hospitalId: _hospitalId);
    
    if (!mounted) return;
    
    if (result != null) {
      // 发布成功
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('发布成功！'),
          backgroundColor: AppColors.brandGreen,
        ),
      );
      context.pop(true); // 返回并传递成功标识
    } else if (provider.submitErrorMessage != null) {
      // 发布失败
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.submitErrorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<CreatePostProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, isDark, provider),
            Expanded(
              child: provider.isLoadingTags
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                      ),
                    )
                  : provider.tagsErrorMessage != null
                      ? _buildErrorView(provider.tagsErrorMessage!)
                      : SingleChildScrollView(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: isDark
                                ? AppColors.darkCardBackground
                                : Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTagSelector(context, isDark, provider),
                                _buildDivider(isDark),
                                _buildTitleField(context, isDark),
                                _buildDivider(isDark),
                                _buildContentField(context, isDark),
                                _buildDivider(isDark),
                                _buildSubmitButton(context, provider),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    bool isDark,
    CreatePostProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (provider.title.isNotEmpty || provider.content.isNotEmpty) {
                // 有内容时提示确认
                showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认退出'),
                    content: const Text('当前内容尚未发布，确定要退出吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('退出'),
                      ),
                    ],
                  ),
                ).then((confirmed) {
                  if (confirmed == true) {
                    context.pop();
                  }
                });
              } else {
                context.pop();
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.brandGreen,
            ),
            padding: EdgeInsets.zero,
            splashRadius: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '返回',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.brandGreen,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Text(
            '发布帖子',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? AppColors.darkNeutralText : null,
                ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // 占位，保持标题居中
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<CreatePostProvider>().loadTags(
                    hospitalId: _hospitalId,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 4,
      color: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
    );
  }

  Widget _buildTagSelector(
    BuildContext context,
    bool isDark,
    CreatePostProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 20,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                '选择标签',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: provider.tags.map((tag) {
              final isSelected = provider.selectedTag?.id == tag.id;
              return _TagChip(
                tag: tag,
                isSelected: isSelected,
                onTap: () => provider.selectTag(tag),
                isDark: isDark,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.title,
                size: 20,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                '标题',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            maxLength: 255,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkNeutralText : null,
            ),
            decoration: InputDecoration(
              hintText: '请输入标题',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkFieldBorder
                      : AppColors.lightFieldBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkFieldBorder
                      : AppColors.lightFieldBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.brandGreen,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkFieldBackground
                  : AppColors.lightFieldBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              context.read<CreatePostProvider>().updateTitle(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentField(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.article_outlined,
                size: 20,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                '内容',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            focusNode: _contentFocusNode,
            maxLines: 12,
            minLines: 8,
            maxLength: 5000,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: isDark ? AppColors.darkNeutralText : null,
            ),
            decoration: InputDecoration(
              hintText: '分享你的想法...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkFieldBorder
                      : AppColors.lightFieldBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkFieldBorder
                      : AppColors.lightFieldBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.brandGreen,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkFieldBackground
                  : AppColors.lightFieldBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              context.read<CreatePostProvider>().updateContent(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, CreatePostProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: provider.canSubmit ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[600],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: provider.isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text(
                  '发布',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final PostTagModel tag;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandGreen
              : isDark
                  ? AppColors.darkFieldBackground
                  : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.brandGreen
                : isDark
                    ? AppColors.darkFieldBorder
                    : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          tag.tagName,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isDark
                    ? AppColors.darkNeutralText
                    : const Color(0xFF1F2937),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

