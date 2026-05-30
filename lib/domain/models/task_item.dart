import '../status.dart';

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.notCompletedReason,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final ItemStatus status;
  final String? notCompletedReason;
  final DateTime createdAt;

  TaskItem copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    ItemStatus? status,
    String? notCompletedReason,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notCompletedReason: notCompletedReason ?? this.notCompletedReason,
      createdAt: createdAt,
    );
  }

  static TaskItem fromRow(Map<String, Object?> row) {
    return TaskItem(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      dueDate: DateTime.parse(row['dueDate'] as String),
      status: ItemStatusDb.fromDb(row['status'] as String),
      notCompletedReason: row['notCompletedReason'] as String?,
      createdAt: DateTime.parse(row['createdAt'] as String),
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status.toDb(),
      'notCompletedReason': notCompletedReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

