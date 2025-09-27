import 'package:intl/intl.dart';

class MockFeed {
  MockFeed({required this.title, required this.publishedAt});

  final String title;
  final DateTime publishedAt;

  String get publishedLabel => DateFormat('yyyy年MM月dd日').format(publishedAt);

  static List<MockFeed> sampleFeed() => [
        MockFeed(
          title: '患者随访问卷上线',
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        MockFeed(
          title: '崖柏临床试验最新进展',
          publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        MockFeed(
          title: '试验中心本周会议要点',
          publishedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
}
