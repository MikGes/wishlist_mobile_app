import '../status.dart';

class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.status,
    required this.notCompletedReason,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final ItemStatus status;
  final String? notCompletedReason;
  final DateTime createdAt;

  WishlistItem copyWith({
    String? title,
    String? description,
    DateTime? scheduledDate,
    ItemStatus? status,
    String? notCompletedReason,
  }) {
    return WishlistItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      notCompletedReason: notCompletedReason ?? this.notCompletedReason,
      createdAt: createdAt,
    );
  }

  static WishlistItem fromRow(Map<String, Object?> row) {
    return WishlistItem(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      scheduledDate: DateTime.parse(row['scheduledDate'] as String),
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
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status.toDb(),
      'notCompletedReason': notCompletedReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

