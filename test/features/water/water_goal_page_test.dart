import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:me_hub/core/providers/theme_provider.dart';
import 'package:me_hub/core/reminders/data/reminder_preferences_repository.dart';
import 'package:me_hub/core/reminders/presentation/reminder_settings_provider.dart';
import 'package:me_hub/core/reminders/services/reminder_coordinator.dart';
import 'package:me_hub/core/reminders/services/reminder_id_registry.dart';
import 'package:me_hub/core/services/notification_service.dart';
import 'package:me_hub/features/water/presentation/pages/water_goal_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'theme_mode': false,
      'water_daily_goal_ml': 2000,
    });
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

  testWidgets('shows reminder controls backed by reminder preferences', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final coordinator = ReminderCoordinator(
      notifications: NotificationService.createForTesting(
        FlutterLocalNotificationsPlugin(),
      ),
      preferencesRepository: ReminderPreferencesRepository(preferences),
      idRegistry: ReminderIdRegistry(preferences),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => ReminderSettingsProvider(coordinator),
          ),
        ],
        child: const MaterialApp(home: WaterGoalPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reminders'), findsOneWidget);
    expect(find.textContaining('Every 2 hours'), findsOneWidget);
  });
}
