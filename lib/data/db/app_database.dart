import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'wishlist_app.sqlite3');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE wishlist(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  scheduledDate TEXT NOT NULL,
  status TEXT NOT NULL,
  notCompletedReason TEXT,
  createdAt TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE notes(
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  style TEXT NOT NULL,
  createdAt TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE tasks(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  dueDate TEXT NOT NULL,
  status TEXT NOT NULL,
  notCompletedReason TEXT,
  createdAt TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE posts_cache(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  createdAt TEXT NOT NULL
)
''');
      },
    );
  }

  Database get db {
    final current = _db;
    if (current == null) {
      throw StateError('Database not initialized. Call AppDatabase.init() first.');
    }
    return current;
  }
}

