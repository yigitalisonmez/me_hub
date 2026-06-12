import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:me_hub/core/providers/theme_provider.dart';
import 'package:me_hub/core/providers/voice_settings_provider.dart';
import 'package:me_hub/core/reminders/data/reminder_preferences_repository.dart';
import 'package:me_hub/core/reminders/presentation/reminder_settings_provider.dart';
import 'package:me_hub/core/reminders/services/reminder_coordinator.dart';
import 'package:me_hub/core/reminders/services/reminder_id_registry.dart';
import 'package:me_hub/core/services/notification_service.dart';
import 'package:me_hub/features/settings/presentation/pages/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'theme_mode': false,
      'voice_locale': 'tr_TR',
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

  testWidgets('groups settings and persists theme and voice choices', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final reminderCoordinator = ReminderCoordinator(
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
          ChangeNotifierProvider(create: (_) => VoiceSettingsProvider()),
          ChangeNotifierProvider(
            create: (_) => ReminderSettingsProvider(reminderCoordinator),
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('🇺🇸 English'), findsOneWidget);
    expect(find.text('🇬🇧 English'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🇺🇸 English'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('theme_mode'), isTrue);
    expect(prefs.getString('voice_locale'), 'en_US');
  });
}
