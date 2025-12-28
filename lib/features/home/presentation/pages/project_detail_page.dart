import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_attrs_section.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_basic_info_section.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_criteria_section.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_files_section.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_staff_section.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_tags_section.dart';
import 'package:yabai_app/features/home/providers/favorite_provider.dart';
import 'package:yabai_app/features/home/providers/project_detail_provider.dart';
import 'package:yabai_app/features/home/providers/share_link_provider.dart';
import 'package:yabai_app/features/screening/presentation/pages/screening_submit_page.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';
import 'package:yabai_app/features/ai/providers/xiaobai_chat_provider.dart';
import 'package:yabai_app/features/ai/presentation/pages/xiaobai_project_chat_page.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  static const routePath = ':id';
  static const routeName = 'project-detail';

  final int projectId;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectDetailProvider>().loadDetail(widget.projectId);
      context.read<FavoriteProvider>().checkFavoriteStatus(widget.projectId);
    });
  }

  Future<void> _toggleFavorite() async {
    final favoriteProvider = context.read<FavoriteProvider>();
    final success = await favoriteProvider.toggleFavorite(widget.projectId);
    
    if (!mounted) return;
    
    if (success) {
      final message = favoriteProvider.isFavorited ? '收藏成功' : '取消收藏成功';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.brandGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(favoriteProvider.errorMessage ?? '操作失败'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 显示分享菜单
  void _showShareMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 在外部读取 ShareLinkProvider，以便在底部表单中访问
    final shareLinkProvider = context.read<ShareLinkProvider>();
    
    showModalBottomSheet(
      context: context,
      useRootNavigator: false, // 使用当前导航栈，确保可以访问 Provider
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return ListenableBuilder(
          listenable: shareLinkProvider,
          builder: (context, child) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSecondaryText : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(
                      Icons.link,
                      color: AppColors.brandGreen,
                    ),
                    title: Text(
                      '复制链接',
                      style: TextStyle(
                        color: isDark ? AppColors.darkNeutralText : Colors.black87,
                      ),
                    ),
                    onTap: shareLinkProvider.isLoading ? null : () {
                      Navigator.pop(bottomSheetContext);
                      _copyProjectLink();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.brandGreen,
                    ),
                    title: Text(
                      '分享到聊天',
                      style: TextStyle(
                        color: isDark ? AppColors.darkNeutralText : Colors.black87,
                      ),
                    ),
                    onTap: shareLinkProvider.isLoading ? null : () {
                      Navigator.pop(bottomSheetContext);
                      _shareToChat();
                    },
                  ),
                  if (shareLinkProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 复制项目链接
  Future<void> _copyProjectLink() async {
    final shareLinkProvider = context.read<ShareLinkProvider>();
    
    try {
      // 调用 API 生成分享链接
      final shareLink = await shareLinkProvider.generateShareLink(widget.projectId);
      
      if (!mounted) return;
      
      if (shareLink != null) {
        // 复制链接到剪贴板
        await Clipboard.setData(ClipboardData(text: shareLink.shareUrl));
        
        // 格式化过期时间
        final expireDateTime = shareLink.expireDateTime;
        final formatter = DateFormat('yyyy年MM月dd日 HH:mm');
        final expireTimeStr = formatter.format(expireDateTime);
        
        // 显示成功提示（包含过期时间）
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('链接已复制，有效期至 $expireTimeStr'),
            backgroundColor: AppColors.brandGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // 显示错误提示
        final errorMsg = shareLinkProvider.errorMessage ?? '生成分享链接失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成分享链接失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 分享到聊天
  Future<void> _shareToChat() async {
    final project = context.read<ProjectDetailProvider>().project;
    if (project == null) return;

    // 构建项目卡片JSON
    final cardData = {
      "cardType": "project",
      "project": {
        "id": project.id,
        "orgId": 0, // TODO: 从项目中获取 orgId
        "title": project.projName,
        "phase": _extractPhase(project),
        "tumorType": project.indication,
        "lineOfTherapy": _extractLineOfTherapy(project),
        "siteCount": _extractSiteCount(project),
        "status": project.progressName,
        "coverFileId": null, // TODO: 从项目中获取封面文件ID
      },
      "snapshotAt": DateTime.now().toIso8601String(),
      "actions": [
        {"type": "deeplink", "label": "查看详情", "url": "yaby://project/${project.id}"},
      ]
    };

    // 跳转到会话选择页面
    if (!mounted) return;
    
    context.pushNamed(
      'select-conversation',
      extra: {
        'shareData': cardData,
        'shareType': 'PROJECT_CARD',
      },
    );
  }

  /// 从项目中提取分期信息
  String? _extractPhase(project) {
    // 从 customAttrs 中提取分期信息
    try {
      final phaseAttr = project.customAttrs.firstWhere(
        (attr) => attr.label == '分期' || attr.label == 'phase',
        orElse: () => null,
      );
      return phaseAttr?.value as String?;
    } catch (e) {
      return null;
    }
  }

  /// 从项目中提取治疗线信息
  String? _extractLineOfTherapy(project) {
    try {
      final lineAttr = project.customAttrs.firstWhere(
        (attr) => attr.label == '治疗线' || attr.label == 'lineOfTherapy',
        orElse: () => null,
      );
      return lineAttr?.value as String?;
    } catch (e) {
      return null;
    }
  }

  /// 从项目中提取中心数量
  int? _extractSiteCount(project) {
    try {
      final siteAttr = project.customAttrs.firstWhere(
        (attr) => attr.label == '中心数' || attr.label == 'siteCount',
        orElse: () => null,
      );
      if (siteAttr?.value is int) {
        return siteAttr.value as int;
      }
      if (siteAttr?.value is String) {
        return int.tryParse(siteAttr.value as String);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _openXiaobaiChat() {
    final project = context.read<ProjectDetailProvider>().project;
    if (project == null) return;
    
    final repository = context.read<AiRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => XiaobaiChatProvider(repository)
            ..initFromProject(
              projectId: project.id,
              projectName: project.projName,
              projectShortTitle: project.shortTitle,
            ),
          child: XiaobaiProjectChatPage(
            projectId: project.id,
            projectName: project.projName,
          ),
        ),
      ),
    );
  }

  void _navigateToScreening() {
    final project = context.read<ProjectDetailProvider>().project;
    if (project == null) return;
    
    context.pushNamed(
      ScreeningSubmitPage.routeName,
      pathParameters: {'id': project.id.toString()},
      extra: {
        'projectId': project.id,
        'projectName': project.projName,
        'criteria': project.criteria,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ProjectDetailProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(provider.project?.projName ?? '项目详情'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : const Color(0xFFF8F9FA),
        actions: [
          IconButton(
            icon: Icon(
              favoriteProvider.isFavorited
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: favoriteProvider.isFavorited
                  ? Colors.red
                  : (isDark ? Colors.white : Colors.black54),
            ),
            onPressed: favoriteProvider.isLoading ? null : _toggleFavorite,
          ),
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: isDark ? Colors.white : Colors.black54,
            ),
            onPressed: provider.project == null ? null : _showShareMenu,
          ),
        ],
      ),
      body: _buildBody(provider, isDark),
      floatingActionButton: provider.project != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 临床问答按钮
                FloatingActionButton.extended(
                  onPressed: () => _openXiaobaiChat(),
                  heroTag: 'xiaobai_chat',
                  backgroundColor: Colors.blue,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    '临床问答',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 筛查患者按钮（原有）
                if (provider.project!.hasCriteria)
                  FloatingActionButton.extended(
                    onPressed: () => _navigateToScreening(),
                    heroTag: 'screening',
                    backgroundColor: AppColors.brandGreen,
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text(
                      '筛查患者',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody(ProjectDetailProvider provider, bool isDark) {
    if (provider.isLoading && provider.project == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    if (provider.errorMessage != null && provider.project == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  provider.loadDetail(widget.projectId);
                },
                style: FilledButton.styleFrom(
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

    if (provider.project == null) {
      return const Center(
        child: Text('项目不存在'),
      );
    }

    final project = provider.project!;

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      color: AppColors.brandGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              color:
                  isDark ? AppColors.darkCardBackground : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 基本信息
                  ProjectBasicInfoSection(
                    project: project,
                    showTopDivider: false,
                    piStaff: project.piStaff,
                  ),
                  // 自定义属性
                  if (project.hasCustomAttrs)
                    ProjectAttrsSection(attrs: project.customAttrs),
                  // 标签
                  if (project.hasCustomTags)
                    ProjectTagsSection(tags: project.customTags),
                  // 入排标准
                  if (project.hasCriteria)
                    ProjectCriteriaSection(criteria: project.criteria),
                  // 附件
                  if (project.hasFiles)
                    ProjectFilesSection(files: project.files),
                  // 人员
                  if (project.hasStaff)
                    ProjectStaffSection(staff: project.staff),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
