// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:yabai_app/app.dart';

void main() {
  testWidgets('Login page renders primary fields', (tester) async {
    await tester.pumpWidget(const YabaiApp());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('登陆'), findsWidgets);
    expect(find.text('请输入您的手机号'), findsOneWidget);
    expect(find.text('记住我'), findsOneWidget);
  });
}
