import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/core/providers/theme_provider.dart';
import 'package:me_hub/core/widgets/celebration_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows metric content and closes from its action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () => showCelebrationDialog(
                        context: context,
                        icon: Icons.check,
                        color: Colors.green,
                        title: 'Goal complete',
                        message: 'A small step is saved.',
                        metric: const CelebrationMetric(
                          before: '2',
                          after: '3',
                          label: 'days',
                        ),
                      ),
                      child: const Text('Open'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.text('Goal complete'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('days'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(find.text('Goal complete'), findsNothing);
  });
}
