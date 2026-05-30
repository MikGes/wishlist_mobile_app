import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../../domain/models/sticky_note.dart';

class NotesRepository {
  const NotesRepository();

  Future<List<StickyNote>> listAll() async {
    final rows = await AppDatabase.instance.db.query(
      'notes',
      orderBy: 'createdAt DESC',
    );
    return rows.map(StickyNote.fromRow).toList(growable: false);
  }

  Future<void> upsert(StickyNote note) async {
    await AppDatabase.instance.db.insert(
      'notes',
      note.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteById(String id) async {
    await AppDatabase.instance.db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}

