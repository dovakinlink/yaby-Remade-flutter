import 'package:intl/intl.dart';

/// 获取下周一的日期
DateTime getNextMonday() {
  final now = DateTime.now();
  // 计算距离下周一的天数
  int daysUntilNextMonday = DateTime.monday - now.weekday + 7;
  if (daysUntilNextMonday == 7) {
    // 如果今天是周一，也返回下周一
    daysUntilNextMonday = 7;
  }
  final nextMonday = now.add(Duration(days: daysUntilNextMonday));
  return DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
}

/// 格式化日期为 yyyy-MM-dd
String formatDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

/// 格式化日期为中文显示格式（如：11月18日 周一）
String formatDateWithWeekday(DateTime date) {
  final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  final weekday = weekdays[date.weekday % 7];
  return '${date.month}月${date.day}日 $weekday';
}

/// 解析 yyyy-MM-dd 格式的日期字符串
DateTime? parseDate(String dateStr) {
  try {
    return DateFormat('yyyy-MM-dd').parse(dateStr);
  } catch (e) {
    return null;
  }
}

