import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../domain/status.dart';
import '../tasks/tasks_store.dart';
import '../wishlist/wishlist_store.dart';

class StatusCounts {
  const StatusCounts({
    required this.pending,
    required this.onTheWay,
    required this.completed,
    required this.notCompleted,
  });

  final int pending;
  final int onTheWay;
  final int completed;
  final int notCompleted;

  int get total => pending + onTheWay + completed + notCompleted;
  double get completionRate => total == 0 ? 0 : completed / total;

  Map<ItemStatus, int> toMap() => {
        ItemStatus.pending: pending,
        ItemStatus.onTheWay: onTheWay,
        ItemStatus.completed: completed,
        ItemStatus.notCompleted: notCompleted,
      };
}

class DashboardStore extends ChangeNotifier {
  StatusCounts wishlist = const StatusCounts(
    pending: 0,
    onTheWay: 0,
    completed: 0,
    notCompleted: 0,
  );
  StatusCounts tasks = const StatusCounts(
    pending: 0,
    onTheWay: 0,
    completed: 0,
    notCompleted: 0,
  );

  final List<int> _weeklyCompleted = List.filled(7, 0);
  UnmodifiableListView<int> get weeklyCompleted =>
      UnmodifiableListView(_weeklyCompleted);

  void recompute(WishlistStore wishlistStore, TasksStore tasksStore) {
    wishlist = _count(wishlistStore.allItems.map((e) => e.status));
    tasks = _count(tasksStore.tasks.map((e) => e.status));
    _computeWeekly(tasksStore, wishlistStore);
    notifyListeners();
  }

  StatusCounts _count(Iterable<ItemStatus> statuses) {
    int pending = 0, onTheWay = 0, completed = 0, notCompleted = 0;
    for (final s in statuses) {
      switch (s) {
        case ItemStatus.pending:
          pending++;
          break;
        case ItemStatus.onTheWay:
          onTheWay++;
          break;
        case ItemStatus.completed:
          completed++;
          break;
        case ItemStatus.notCompleted:
          notCompleted++;
          break;
      }
    }
    return StatusCounts(
      pending: pending,
      onTheWay: onTheWay,
      completed: completed,
      notCompleted: notCompleted,
    );
  }

  void _computeWeekly(TasksStore tasksStore, WishlistStore wishlistStore) {
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      _weeklyCompleted[i] = 0;
    }

    bool inSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    for (var i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));

      final completedTasks = tasksStore.tasks.where((t) =>
          t.status == ItemStatus.completed && inSameDay(t.dueDate, day));
      final completedWishlist = wishlistStore.allItems.where((w) =>
          w.status == ItemStatus.completed && inSameDay(w.scheduledDate, day));
      _weeklyCompleted[i] = completedTasks.length + completedWishlist.length;
    }
  }
}

