import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../../domain/models/task_item.dart';

class TasksRepository {
  const TasksRepository();

  Future<List<TaskItem>> listAll() async {
    final rows = await AppDatabase.instance.db.query(
      'tasks',
      orderBy: 'dueDate ASC',
    );
    return rows.map(TaskItem.fromRow).toList(growable: false);
  }

  Future<void> upsert(TaskItem item) async {
    await AppDatabase.instance.db.insert(
      'tasks',
      item.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteById(String id) async {
    await AppDatabase.instance.db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}

