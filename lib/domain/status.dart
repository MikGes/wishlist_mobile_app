enum ItemStatus {
  pending,
  onTheWay,
  completed,
  notCompleted,
}

extension ItemStatusDb on ItemStatus {
  String toDb() => switch (this) {
        ItemStatus.pending => 'pending',
        ItemStatus.onTheWay => 'on_the_way',
        ItemStatus.completed => 'completed',
        ItemStatus.notCompleted => 'not_completed',
      };

  static ItemStatus fromDb(String value) => switch (value) {
        'pending' => ItemStatus.pending,
        'on_the_way' => ItemStatus.onTheWay,
        'completed' => ItemStatus.completed,
        'not_completed' => ItemStatus.notCompleted,
        _ => ItemStatus.pending,
      };
}

