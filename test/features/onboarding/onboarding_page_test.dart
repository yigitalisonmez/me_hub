import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/core/providers/theme_provider.dart';
import 'package:me_hub/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'theme_mode': false});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_native_splash'),
          (_) async => null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_native_splash'),
          null,
        );
  });

  testWidgets('follows the redesigned onboarding flow without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MaterialApp(home: OnboardingPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Your calm, organized day - all in one place.'), findsOne);
    expect(find.text('Get started'), findsOne);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Get started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('A gentle space for everything you care about.'),
      findsOne,
    );
    expect(find.text('Plan with intention'), findsOne);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('First, what should we call you?'), findsOne);

    await tester.enterText(
      find.byKey(const Key('onboarding_name_field')),
      'Mira',
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('What would you like to focus on?'), findsOne);
    expect(find.text('Tasks'), findsOne);
    expect(find.text('Gratitude'), findsOne);
    expect(find.text('Start my journey'), findsOne);
    expect(tester.takeException(), isNull);
  });
}
