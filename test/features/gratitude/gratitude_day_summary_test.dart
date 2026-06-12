import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/features/gratitude/domain/entities/gratitude_entry.dart';
import 'package:me_hub/features/gratitude/domain/entities/gratitude_item.dart';
import 'package:me_hub/features/gratitude/presentation/models/gratitude_day_summary.dart';

void main() {
  GratitudeItem item(String id, String content) {
    return GratitudeItem(
      id: id,
      content: content,
      createdAtTimestamp: DateTime(2026, 6, 12).millisecondsSinceEpoch,
    );
  }

  GratitudeEntry entry({
    required String id,
    required DateTime date,
    required EntryType type,
    required List<GratitudeItem> items,
  }) {
    return GratitudeEntry(
      id: id,
      dateTimestamp: date.millisecondsSinceEpoch,
      items: items,
      entryType: type,
    );
  }

  test('builds a 14 day garden ending today', () {
    final garden = buildGratitudeGarden(
      const [],
      now: DateTime(2026, 6, 12, 18),
    );

    expect(garden, hasLength(14));
    expect(garden.first.date, DateTime(2026, 5, 30));
    expect(garden.last.date, DateTime(2026, 6, 12));
    expect(garden.every((day) => day.progressCount == 0), isTrue);
  });

  test('combines morning and evening entries and caps progress at three', () {
    final garden = buildGratitudeGarden([
      entry(
        id: 'evening',
        date: DateTime(2026, 6, 12, 21),
        type: EntryType.evening,
        items: [item('3', 'Quiet dinner'), item('4', 'Good book')],
      ),
      entry(
        id: 'morning',
        date: DateTime(2026, 6, 12, 8),
        type: EntryType.morning,
        items: [item('1', 'Sunlight'), item('2', 'Fresh coffee')],
      ),
    ], now: DateTime(2026, 6, 12, 22));

    final today = garden.last;
    expect(today.entries.map((entry) => entry.id), ['morning', 'evening']);
    expect(today.items, hasLength(4));
    expect(today.progressCount, 3);
    expect(today.isComplete, isTrue);
  });
}
