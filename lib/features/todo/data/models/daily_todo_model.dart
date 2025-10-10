import 'package:hive/hive.dart';
import '../../domain/entities/daily_todo.dart';

part 'daily_todo_model.g.dart';

/// DailyTodo Hive model'i
@HiveType(typeId: 1)
class DailyTodoModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? completedAt;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  int priority;

  DailyTodoModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    required this.date,
    this.priority = 2,
  });

  /// Convert from entity to model
  factory DailyTodoModel.fromEntity(DailyTodo entity) {
    return DailyTodoModel(
      id: entity.id,
      title: entity.title,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
      date: entity.date,
      priority: entity.priority,
    );
  }

  /// Convert from model to entity
  DailyTodo toEntity() {
    return DailyTodo(
      id: id,
      title: title,
      isCompleted: isCompleted,
      createdAt: createdAt,
      completedAt: completedAt,
      date: date,
      priority: priority,
    );
  }

  /// Create model from JSON
  factory DailyTodoModel.fromJson(Map<String, dynamic> json) {
    return DailyTodoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      date: DateTime.parse(json['date'] as String),
      priority: json['priority'] as int? ?? 2,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'date': date.toIso8601String(),
      'priority': priority,
    };
  }
}
