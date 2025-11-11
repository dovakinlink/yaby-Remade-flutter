import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yabai_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化中文日期格式
  await initializeDateFormatting('zh_CN', null);
  runApp(const YabaiApp());
}
