import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../core/utils/ids.dart';
import '../../data/repositories/notes_repository.dart';
import '../../domain/models/sticky_note.dart';

class NotesStore extends ChangeNotifier {
  final NotesRepository _repo = const NotesRepository();

  final List<StickyNote> _notes = [];
  UnmodifiableListView<StickyNote> get notes => UnmodifiableListView(_notes);

  bool isLoading = false;
  String? lastError;

  Future<void> load() async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final all = await _repo.listAll();
      _notes
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
    required String content,
    StickyNoteStyle? style,
  }) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('Note content cannot be empty.');
    }
    final note = StickyNote(
      id: newId(),
      content: content.trim(),
      style: style ??
          const StickyNoteStyle(
            colorHex: 0xFFFFF3B0,
            fontSize: 16,
            fontFamily: 'Roboto',
            layout: 'bullet',
          ),
      createdAt: DateTime.now(),
    );
    await _repo.upsert(note);
    _notes.insert(0, note);
    notifyListeners();
  }

  Future<void> update(StickyNote note) async {
    await _repo.upsert(note);
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) _notes[idx] = note;
    notifyListeners();
  }

  Future<void> delete(StickyNote note) async {
    await _repo.deleteById(note.id);
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();
  }
}

