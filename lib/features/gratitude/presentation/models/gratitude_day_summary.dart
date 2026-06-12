import 'dart:math' as math;

import '../../domain/entities/gratitude_entry.dart';
import '../../domain/entities/gratitude_item.dart';

class GratitudeDaySummary {
  final DateTime date;
  final List<GratitudeEntry> entries;

  const GratitudeDaySummary({required this.date, required this.entries});

  List<GratitudeItem> get items => [
    for (final entry in entries) ...entry.items,
  ];

  int get progressCount => math.min(3, items.length);
  bool get isComplete => progressCount == 3;
}

List<GratitudeDaySummary> buildGratitudeGarden(
  List<GratitudeEntry> entries, {
  DateTime? now,
  int days = 14,
}) {
  assert(days > 0);
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final grouped = <DateTime, List<GratitudeEntry>>{};

  for (final entry in entries) {
    grouped.putIfAbsent(entry.normalizedDate, () => []).add(entry);
  }

  for (final dayEntries in grouped.values) {
    dayEntries.sort((a, b) => a.dateTimestamp.compareTo(b.dateTimestamp));
  }

  return List.generate(days, (index) {
    final date = today.subtract(Duration(days: days - index - 1));
    return GratitudeDaySummary(
      date: date,
      entries: List.unmodifiable(grouped[date] ?? const <GratitudeEntry>[]),
    );
  });
}
