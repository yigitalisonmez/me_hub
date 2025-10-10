// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/features/todo/data/datasources/todo_local_datasource.dart';

import 'package:me_hub/main.dart';

void main() {
  testWidgets('Me Hub app smoke test', (WidgetTester tester) async {
    // Mock todo data source
    final mockDataSource = TodoLocalDataSourceImpl();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MeHubApp(todoDataSource: mockDataSource));

    // Verify that our app title is displayed.
    expect(find.text('Me Hub'), findsAtLeastNWidgets(1));
    expect(find.text('All-in-one personal tracking app'), findsOneWidget);
  });
}
