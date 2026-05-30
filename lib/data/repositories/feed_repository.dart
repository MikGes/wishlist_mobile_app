import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../../domain/models/post.dart';

class FeedRepository {
  const FeedRepository();

  /// The API is intentionally simple: a single GET returning a list of posts.
  ///
  /// For offline/dev, callers can pass [baseUrl] = 'mock' to return local content.
  Future<List<Post>> fetchRemote({required String baseUrl}) async {
    if (baseUrl == 'mock') {
      return _mockPosts();
    }

    final uri = _buildFeedUri(baseUrl);
    final res = await http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Feed request failed: ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);

    if (_isDevTo(baseUrl)) {
      final list = (decoded is List) ? decoded : const [];
      return list
          .cast<Map>()
          .map((m) => _postFromDevTo(m.cast<String, Object?>()))
          .toList(growable: false);
    }

    final list = (decoded is List)
        ? decoded
        : (decoded['items'] as List? ?? const []);
    return list
        .cast<Map>()
        .map((m) => _postFromJson(m.cast<String, Object?>()))
        .toList(growable: false);
  }

  Future<List<Post>> loadCached() async {
    final rows = await AppDatabase.instance.db.query(
      'posts_cache',
      orderBy: 'createdAt DESC',
      limit: 200,
    );
    return rows.map(Post.fromRow).toList(growable: false);
  }

  Future<void> replaceCache(List<Post> posts) async {
    final db = AppDatabase.instance.db;
    final batch = db.batch();
    batch.delete('posts_cache');
    for (final p in posts) {
      batch.insert('posts_cache', p.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Post _postFromJson(Map<String, Object?> json) {
    return Post(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      category: (json['category'] ?? 'motivation').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  bool _isDevTo(String baseUrl) => baseUrl.contains('dev.to');

  Uri _buildFeedUri(String baseUrl) {
    if (_isDevTo(baseUrl)) {
      // dev.to public API: https://developers.forem.com/api
      return Uri.parse('$baseUrl/api/articles?per_page=25&top=7');
    }
    return Uri.parse('$baseUrl/api/posts');
  }

  Post _postFromDevTo(Map<String, Object?> json) {
    final id = (json['id'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final description = (json['description'] ?? '').toString();
    final tagsRaw = json['tag_list'];
    final tags = (tagsRaw is List)
        ? tagsRaw.map((e) => e.toString()).toList(growable: false)
        : <String>[];
    final category = tags.isNotEmpty ? tags.first : 'dev.to';
    final createdAt = DateTime.tryParse((json['published_at'] ?? '').toString()) ??
        DateTime.tryParse((json['created_at'] ?? '').toString()) ??
        DateTime.now();

    return Post(
      id: id,
      title: title,
      content: description.isEmpty ? 'Open to read more on dev.to' : description,
      category: category,
      createdAt: createdAt,
    );
  }

  List<Post> _mockPosts() {
    final now = DateTime.now();
    return [
      Post(
        id: 'm1',
        title: 'Do the next small thing',
        content:
            'Momentum comes from finishing tiny steps. Pick one task you can complete in 10 minutes.',
        category: 'productivity',
        createdAt: now,
      ),
      Post(
        id: 'm2',
        title: 'Consistency beats intensity',
        content:
            'A calm daily routine beats a perfect plan you never repeat. Show up, adjust, repeat.',
        category: 'motivation',
        createdAt: now.subtract(const Duration(hours: 10)),
      ),
      Post(
        id: 'm3',
        title: 'Tech: Offline-first mindset',
        content:
            'Store locally, sync later. Your app should still feel great without a network.',
        category: 'tech',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}

