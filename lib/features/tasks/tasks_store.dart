import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../core/utils/ids.dart';
import '../../data/repositories/tasks_repository.dart';
import '../../domain/models/task_item.dart';
import '../../domain/status.dart';

class TasksStore extends ChangeNotifier {
  final TasksRepository _repo = const TasksRepository();

  final List<TaskItem> _tasks = [];
  UnmodifiableListView<TaskItem> get tasks => UnmodifiableListView(_tasks);

  bool isLoading = false;
  String? lastError;

  Future<void> load() async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final all = await _repo.listAll();
      _tasks
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
    required DateTime dueDate,
  }) async {
    final now = DateTime.now();
    final task = TaskItem(
      id: newId(),
      title: title.trim(),
      description: (description?.trim().isEmpty ?? true) ? null : description!.trim(),
      dueDate: dueDate,
      status: ItemStatus.pending,
      notCompletedReason: null,
      createdAt: now,
    );
    await _repo.upsert(task);
    _tasks.add(task);
    notifyListeners();
  }

  Future<void> updateStatus(
    TaskItem task,
    ItemStatus status, {
    String? notCompletedReason,
  }) async {
    if (status == ItemStatus.notCompleted &&
        (notCompletedReason == null || notCompletedReason.trim().isEmpty)) {
      throw ArgumentError('Reason is required when status is not completed.');
    }
    final updated = task.copyWith(
      status: status,
      notCompletedReason: status == ItemStatus.notCompleted
          ? notCompletedReason!.trim()
          : null,
    );
    await _repo.upsert(updated);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) _tasks[idx] = updated;
    notifyListeners();
  }

  Future<void> delete(TaskItem task) async {
    await _repo.deleteById(task.id);
    _tasks.removeWhere((t) => t.id == task.id);
    notifyListeners();
  }
}

