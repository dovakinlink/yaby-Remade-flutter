import 'package:intl/intl.dart';

enum MockFeedType { announcement, task, alert, survey }

class MockFeed {
  const MockFeed({
    required this.type,
    required this.title,
    required this.publishedAt,
    this.description,
    this.tag,
    this.participants,
    this.progress,
    this.badgeText,
  });

  final MockFeedType type;
  final String title;
  final String? description;
  final DateTime publishedAt;
  final String? tag;
  final int? participants;
  final double? progress;
  final String? badgeText;

  String get publishedLabel {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟之前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时之前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天之前';
    } else {
      return DateFormat('yyyy年MM月dd日').format(publishedAt);
    }
  }

  MockFeed copyWith({
    MockFeedType? type,
    String? title,
    String? description,
    DateTime? publishedAt,
    String? tag,
    int? participants,
    double? progress,
    String? badgeText,
  }) {
    return MockFeed(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      publishedAt: publishedAt ?? this.publishedAt,
      tag: tag ?? this.tag,
      participants: participants ?? this.participants,
      progress: progress ?? this.progress,
      badgeText: badgeText ?? this.badgeText,
    );
  }

  static List<MockFeed> sampleFeed({int page = 0}) {
    final baseDate = DateTime.now();
    
    if (page == 0) {
      // 首页内容，严格按照设计图
      final items = <MockFeed>[
        MockFeed(
          type: MockFeedType.announcement,
          title: 'CRC和CRA需要做的几件事儿',
          description: '1.通知自己的同事，查看是否因不确认微信群内金山文档《人员信息表》而被删除账号。若被删除请发送微信与管理系统再次申请：\n2.确认自己项目的以下信...',
          publishedAt: baseDate.subtract(const Duration(hours: 15)),
          tag: '通知',
          badgeText: '通知',
        ),
        MockFeed(
          type: MockFeedType.task,
          title: '评价SSGJ-705单药在晚期恶性肿瘤患者中的安全性、耐受性和初步疗效的I期临床研究',
          description: '入组人群：\n1）年龄≥18岁，≤75岁男性或女性；\n2）预期生存时间≥3个月\n3）经组织学或细胞学证...',
          publishedAt: baseDate.subtract(const Duration(days: 1)),
          participants: 1,
          badgeText: '项目启动',
        ),
      ];
      return List<MockFeed>.unmodifiable(items);
    } else {
      // 其他页面内容
      final dayOffset = page * 2;
      final suffix = '第${page + 1}批';
      final items = <MockFeed>[
        MockFeed(
          type: MockFeedType.announcement,
          title: '患者随访问卷上线 · $suffix',
          description: '新版问卷已发布，建议在本周内通知全部受试者完成填写。',
          publishedAt: baseDate.subtract(Duration(days: dayOffset + 1)),
          tag: '项目更新',
          badgeText: '重要',
        ),
        MockFeed(
          type: MockFeedType.task,
          title: '东华医院 · 受试者随访准备 · $suffix',
          description: '第 3 访视即将开始，请完成访前检查与资料同步。',
          publishedAt: baseDate.subtract(Duration(days: dayOffset + 2)),
          participants: 18 + page * 6,
          progress: 0.62,
          badgeText: '进行中',
        ),
      ];
      return List<MockFeed>.unmodifiable(items);
    }
  }
}
