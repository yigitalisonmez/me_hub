import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:me_hub/core/providers/theme_provider.dart';
import 'package:me_hub/core/widgets/animated_metric_text.dart';
import 'package:me_hub/features/profile/presentation/pages/profile_page.dart';
import 'package:me_hub/features/water/domain/entities/water_intake.dart';
import 'package:me_hub/features/water/domain/repositories/water_repository.dart';
import 'package:me_hub/features/water/domain/usecases/usecases.dart';
import 'package:me_hub/features/water/presentation/providers/water_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'theme_mode': false,
      'water_daily_goal_ml': 2500,
      'cumulative_stats_migrated_v1': true,
      'cumulative_all_time_water_ml': 1250,
      'cumulative_all_time_tasks_done': 2,
      'cumulative_max_streak': 1,
    });
    FlutterSecureStorage.setMockInitialValues({'user_name': 'Ada'});
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

  testWidgets('shows the real water goal without misleading profile controls', (
    tester,
  ) async {
    final waterProvider = _buildWaterProvider();
    await _pumpProfile(tester, waterProvider);

    expect(find.text('2500 ml · 10 glasses'), findsOneWidget);
    expect(find.text('Dark mode'), findsNothing);
    expect(find.text('Reminders'), findsNothing);
    expect(find.text('Privacy'), findsNothing);
    expect(find.text('See full report'), findsNothing);
    expect(find.textContaining('core rhythm signals'), findsNothing);
    expect(find.byIcon(LucideIcons.chevronRight), findsNWidgets(2));
    expect(find.byType(AnimatedMetricText), findsNWidgets(3));
  });

  testWidgets('updates the profile label and WaterProvider after saving', (
    tester,
  ) async {
    final waterProvider = _buildWaterProvider();
    await _pumpProfile(tester, waterProvider);

    final waterGoal = find.text('Water goal');
    await tester.ensureVisible(waterGoal);
    await tester.tap(waterGoal);
    await tester.pumpAndSettle();

    expect(find.text('Water Settings'), findsOneWidget);

    final preset = find.text('3000ml');
    await tester.ensureVisible(preset);
    await tester.tap(preset);
    await tester.pump();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('3000 ml · 12 glasses'), findsOneWidget);
    expect(waterProvider.dailyGoalMl, 3000);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('water_daily_goal_ml'), 3000);
  });
}

Future<void> _pumpProfile(
  WidgetTester tester,
  WaterProvider waterProvider,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: waterProvider),
      ],
      child: const MaterialApp(home: ProfilePage()),
    ),
  );
  await tester.pumpAndSettle();
}

WaterProvider _buildWaterProvider() {
  final repository = _FakeWaterRepository();
  return WaterProvider(
    getTodayWaterIntake: GetTodayWaterIntake(repository),
    addWater: AddWater(repository),
    removeLastLog: RemoveLastLog(repository),
    updateWaterIntake: UpdateWaterIntake(repository),
  );
}

class _FakeWaterRepository implements WaterRepository {
  @override
  Future<void> addWater(DateTime date, int amountMl) async {}

  @override
  Future<WaterIntake?> getTodayWaterIntake() async => null;

  @override
  Future<void> removeLastLog(DateTime date) async {}

  @override
  Future<void> updateWaterIntake(WaterIntake waterIntake) async {}

  @override
  Future<List<WaterIntake>> getAllWaterIntakes() async => const [];
}
