import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../data/repositories/feed_repository.dart';
import '../../domain/models/post.dart';

class FeedStore extends ChangeNotifier {
  final FeedRepository _repo = const FeedRepository();

  final List<Post> _posts = [];
  UnmodifiableListView<Post> get posts => UnmodifiableListView(_posts);

  bool isLoading = false;
  String? lastError;

  /// Public, well-known API (no auth required).
  /// Uses dev.to articles as a simple “feed” source.
  String baseUrl = 'https://dev.to';

  Future<void> loadCached() async {
    try {
      final cached = await _repo.loadCached();
      _posts
        ..clear()
        ..addAll(cached);
      notifyListeners();
    } catch (_) {
      // ignore cache read errors
    }
  }

  Future<void> refresh() async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final remote = await _repo.fetchRemote(baseUrl: baseUrl);
      _posts
        ..clear()
        ..addAll(remote);
      await _repo.replaceCache(remote);
    } catch (e) {
      lastError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

