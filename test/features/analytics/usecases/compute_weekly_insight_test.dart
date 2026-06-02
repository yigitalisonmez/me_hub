import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:me_hub/features/analytics/domain/usecases/compute_weekly_insight.dart';
import 'package:me_hub/features/mood_tracker/domain/entities/mood_entry.dart';
import 'package:me_hub/features/water/domain/entities/water_intake.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('insight_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(30)) Hive.registerAdapter(MoodEntryAdapter());
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(WaterIntakeAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) Hive.registerAdapter(WaterLogAdapter());
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('ComputeWeeklyInsight', () {
    test('returns null when fewer than 3 mood entries exist', () async {
      final moodBox = await Hive.openBox<MoodEntry>('mood_entries');
      final waterBox = await Hive.openBox<WaterIntake>('water_intake');

      // Only 2 mood entries — below the 3-entry threshold.
      final now = DateTime.now().millisecondsSinceEpoch;
      await moodBox.add(MoodEntry(id: 'm1', score: 7, dateTimestamp: now));
      await moodBox.add(
        MoodEntry(id: 'm2', score: 8, dateTimestamp: now - 86400000),
      );

      // 5 water entries — doesn't matter, mood is the bottleneck.
      for (var i = 0; i < 5; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        await waterBox.add(
          WaterIntake(id: 'w$i', date: date, amountMl: 2000, logs: const []),
        );
      }

      final result = await ComputeWeeklyInsight()();
      expect(result, isNull);
    });

    test('returns null when fewer than 3 water entries exist', () async {
      final moodBox = await Hive.openBox<MoodEntry>('mood_entries');
      final waterBox = await Hive.openBox<WaterIntake>('water_intake');

      for (var i = 0; i < 5; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        await moodBox.add(
          MoodEntry(
            id: 'm$i',
            score: 6 + i % 4,
            dateTimestamp: date.millisecondsSinceEpoch,
          ),
        );
      }

      // Only 2 water entries.
      for (var i = 0; i < 2; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        await waterBox.add(
          WaterIntake(id: 'w$i', date: date, amountMl: 1500, logs: const []),
        );
      }

      final result = await ComputeWeeklyInsight()();
      expect(result, isNull);
    });

    test(
      'returns non-null string when 5+ aligned mood + water entries with strong correlation',
      () async {
        final moodBox = await Hive.openBox<MoodEntry>('mood_entries');
        final waterBox = await Hive.openBox<WaterIntake>('water_intake');

        // Seed 7 days where high water (>2000ml) aligns with high mood (8-10)
        // and low water (<1000ml) aligns with low mood (3-5).
        // This produces a strong positive Pearson r.
        final data = [
          (water: 2500, mood: 9),
          (water: 2200, mood: 8),
          (water: 800, mood: 4),
          (water: 2800, mood: 10),
          (water: 600, mood: 3),
          (water: 2100, mood: 8),
          (water: 700, mood: 4),
        ];

        for (var i = 0; i < data.length; i++) {
          final date = DateTime.now().subtract(Duration(days: i));
          await moodBox.add(
            MoodEntry(
              id: 'm$i',
              score: data[i].mood,
              dateTimestamp: date.millisecondsSinceEpoch,
            ),
          );
          await waterBox.add(
            WaterIntake(
              id: 'w$i',
              date: date,
              amountMl: data[i].water,
              logs: const [],
            ),
          );
        }

        final result = await ComputeWeeklyInsight()();
        expect(result, isNotNull);
        expect(result, isA<String>());
        expect(result!.isNotEmpty, isTrue);
      },
    );
  });
}
