import 'package:hive/hive.dart';

part 'daily_todo.g.dart';

/// Günlük todo entity'si
@HiveType(typeId: 0)
class DailyTodo extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final bool isCompleted;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? completedAt;

  @HiveField(5)
  final DateTime date; // Which day it belongs to

  @HiveField(6)
  final int priority; // 1: Low, 2: Medium, 3: High

  DailyTodo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    required this.date,
    this.priority = 2,
  });

  /// Mark todo as completed
  DailyTodo markAsCompleted() {
    return copyWith(isCompleted: true, completedAt: DateTime.now());
  }

  /// Mark todo as incomplete
  DailyTodo markAsIncomplete() {
    return copyWith(isCompleted: false, completedAt: null);
  }

  /// Update todo
  DailyTodo copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? date,
    int? priority,
  }) {
    return DailyTodo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      date: date ?? this.date,
      priority: priority ?? this.priority,
    );
  }

  /// Get priority level as string
  String get priorityText {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Medium';
    }
  }

  /// Get priority color
  String get priorityColor {
    switch (priority) {
      case 1:
        return '#10B981'; // Green
      case 2:
        return '#F59E0B'; // Yellow
      case 3:
        return '#EF4444'; // Red
      default:
        return '#F59E0B';
    }
  }

  /// Check if it's today's todo
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if it's a past todo
  bool get isPast {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Check if it's a future todo
  bool get isFuture {
    final now = DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyTodo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DailyTodo(id: $id, title: $title, isCompleted: $isCompleted, date: $date)';
  }
}
