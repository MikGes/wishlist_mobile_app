import '../db/app_database.dart';
import '../../domain/models/wishlist_item.dart';
import 'package:sqflite/sqflite.dart';

class WishlistRepository {
  const WishlistRepository();

  Future<List<WishlistItem>> listAll() async {
    final rows = await AppDatabase.instance.db.query(
      'wishlist',
      orderBy: 'scheduledDate ASC',
    );
    return rows.map(WishlistItem.fromRow).toList(growable: false);
  }

  Future<void> upsert(WishlistItem item) async {
    await AppDatabase.instance.db.insert(
      'wishlist',
      item.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteById(String id) async {
    await AppDatabase.instance.db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
  }
}

