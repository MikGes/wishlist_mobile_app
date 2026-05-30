import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../core/utils/ids.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/status.dart';
import '../../services/local_notifications_service.dart';

class WishlistStore extends ChangeNotifier {
  final WishlistRepository _repo = const WishlistRepository();

  final List<WishlistItem> _items = [];
  UnmodifiableListView<WishlistItem> get allItems => UnmodifiableListView(_items);
  UnmodifiableListView<WishlistItem> get items =>
      UnmodifiableListView(_filteredAndSorted());

  ItemStatus? filterStatus;
  DateTime? filterDate;

  bool isLoading = false;
  String? lastError;

  Future<void> load() async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final all = await _repo.listAll();
      _items
        ..clear()
        ..addAll(all);
    } catch (e) {
      lastError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add({
    required String title,
    String? description,
    required DateTime scheduledDate,
  }) async {
    final now = DateTime.now();
    final item = WishlistItem(
      id: newId(),
      title: title.trim(),
      description: (description?.trim().isEmpty ?? true) ? null : description!.trim(),
      scheduledDate: scheduledDate,
      status: ItemStatus.pending,
      notCompletedReason: null,
      createdAt: now,
    );
    await _repo.upsert(item);
    _items.add(item);

    // Best-effort reminder on the scheduled day.
    await LocalNotificationsService.instance.schedule(
      id: item.id.hashCode,
      title: 'Scheduled buy',
      body: item.title,
      when: DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        9,
        0,
      ),
    );

    notifyListeners();
  }

  Future<void> updateStatus(
    WishlistItem item,
    ItemStatus status, {
    String? notCompletedReason,
  }) async {
    if (status == ItemStatus.notCompleted &&
        (notCompletedReason == null || notCompletedReason.trim().isEmpty)) {
      throw ArgumentError('Reason is required when status is not completed.');
    }
    final updated = item.copyWith(
      status: status,
      notCompletedReason: status == ItemStatus.notCompleted
          ? notCompletedReason!.trim()
          : null,
    );
    await _repo.upsert(updated);
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx != -1) _items[idx] = updated;
    notifyListeners();
  }

  Future<void> delete(WishlistItem item) async {
    await _repo.deleteById(item.id);
    await LocalNotificationsService.instance.cancel(item.id.hashCode);
    _items.removeWhere((e) => e.id == item.id);
    notifyListeners();
  }

  void setFilters({ItemStatus? status, DateTime? date}) {
    filterStatus = status;
    filterDate = date;
    notifyListeners();
  }

  void clearFilters() {
    filterStatus = null;
    filterDate = null;
    notifyListeners();
  }

  List<WishlistItem> _filteredAndSorted() {
    Iterable<WishlistItem> res = _items;
    if (filterStatus != null) {
      res = res.where((e) => e.status == filterStatus);
    }
    if (filterDate != null) {
      final d = filterDate!;
      res = res.where((e) =>
          e.scheduledDate.year == d.year &&
          e.scheduledDate.month == d.month &&
          e.scheduledDate.day == d.day);
    }

    // Urgency: nearest scheduledDate first; then pending/on_the_way before completed.
    final list = res.toList(growable: false);
    list.sort((a, b) {
      final date = a.scheduledDate.compareTo(b.scheduledDate);
      if (date != 0) return date;
      final rank = _statusRank(a.status).compareTo(_statusRank(b.status));
      if (rank != 0) return rank;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  int _statusRank(ItemStatus s) => switch (s) {
        ItemStatus.pending => 0,
        ItemStatus.onTheWay => 1,
        ItemStatus.notCompleted => 2,
        ItemStatus.completed => 3,
      };
}

