import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:me_hub/features/mood_tracker/data/datasources/mood_local_datasource.dart';
import 'package:me_hub/features/mood_tracker/domain/entities/mood_entry.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mood_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(30)) Hive.registerAdapter(MoodEntryAdapter());
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('MoodLocalDataSource.init()', () {
    test('normal init opens box and data is accessible', () async {
      final ds = MoodLocalDataSource();
      await ds.init();

      final now = DateTime.now();
      final entry = MoodEntry(
        id: 'test-1',
        score: 8,
        dateTimestamp: now.millisecondsSinceEpoch,
      );
      await ds.saveMoodEntry(entry);

      final loaded = await ds.getTodayMood();
      expect(loaded, isNotNull);
      expect(loaded!.score, 8);
    });

    test(
      'init with invalid box file completes and datasource is usable',
      () async {
        // Write bytes that are not a valid Hive box. In production Hive throws
        // HiveError and MoodLocalDataSource recovers. In the test VM, Hive may
        // handle this differently — either way init() must not propagate an error
        // and the datasource must be usable afterward.
        final corruptFile = File('${tempDir.path}/mood_entries.hive');
        await corruptFile.writeAsBytes(
          [0x00, 0xFF, 0xDE, 0xAD, ...List.filled(128, 0xFF)],
        );

        final ds = MoodLocalDataSource();
        await expectLater(ds.init(), completes);

        final entry = MoodEntry(
          id: 'post-init',
          score: 5,
          dateTimestamp: DateTime.now().millisecondsSinceEpoch,
        );
        await ds.saveMoodEntry(entry);
        final loaded = await ds.getTodayMood();
        expect(loaded?.score, 5);
      },
    );

    test(
      'checkAndClearRecoveryFlag is false and idempotent when no recovery',
      () async {
        final recovered = await MoodLocalDataSource.checkAndClearRecoveryFlag();
        expect(recovered, isFalse);

        final recovered2 =
            await MoodLocalDataSource.checkAndClearRecoveryFlag();
        expect(recovered2, isFalse);
      },
    );

    test(
      'checkAndClearRecoveryFlag clears flag after returning true',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('mood_data_recovered', true);

        final first = await MoodLocalDataSource.checkAndClearRecoveryFlag();
        expect(first, isTrue);

        final second = await MoodLocalDataSource.checkAndClearRecoveryFlag();
        expect(second, isFalse);
      },
    );
  });

  group('MoodLocalDataSource CRUD', () {
    late MoodLocalDataSource ds;

    setUp(() async {
      ds = MoodLocalDataSource();
      await ds.init();
    });

    test('saveMoodEntry and getMoodEntry round-trip', () async {
      final date = DateTime(2026, 1, 15);
      final entry = MoodEntry(
        id: 'entry-1',
        score: 7,
        dateTimestamp: date.millisecondsSinceEpoch,
      );
      await ds.saveMoodEntry(entry);
      final loaded = await ds.getMoodEntry(date);
      expect(loaded?.score, 7);
    });

    test('getAllMoodEntries returns all saved entries', () async {
      for (var i = 1; i <= 5; i++) {
        await ds.saveMoodEntry(
          MoodEntry(
            id: 'entry-$i',
            score: i * 2,
            dateTimestamp: DateTime(2026, 1, i).millisecondsSinceEpoch,
          ),
        );
      }
      final all = await ds.getAllMoodEntries();
      expect(all.length, 5);
    });
  });
}
