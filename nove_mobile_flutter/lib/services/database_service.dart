import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import 'dart:io';
import 'dart:convert';

class DatabaseService {
  static final List<Note> _notes = [];
  static bool _initialized = false;

  // ─── File Accessors ──────────────────────────────────────────────────────

  static Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File(join(directory.path, 'nove_notes.json'));
  }

  static Future<File> get _versionsFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File(join(directory.path, 'nove_versions.json'));
  }

  // ─── Initialization ───────────────────────────────────────────────────────

  /// Load notes from disk into memory. Safe to call multiple times.
  static Future<void> init({bool forceReload = false}) async {
    if (_initialized && !forceReload) return;
    try {
      final file = await _file;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
        _notes.clear();
        _notes.addAll(
          jsonList
              .whereType<Map<String, dynamic>>()
              .map((j) => Note.fromJson(j)),
        );
      }
    } catch (e) {
      debugPrint('DatabaseService.init error: $e');
    }
    _initialized = true;
  }

  static Future<void> _save() async {
    try {
      final file = await _file;
      final jsonList = _notes.map((n) => n.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('DatabaseService._save error: $e');
    }
  }

  static Future<void> close() async {
    _notes.clear();
    _initialized = false;
  }

  // ─── Sort Helper ──────────────────────────────────────────────────────────

  static int _sortNotes(Note a, Note b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    return b.updatedAt.compareTo(a.updatedAt);
  }

  // ─── Queries ──────────────────────────────────────────────────────────────

  static Future<List<Note>> getAllNotes() async {
    await init();
    return _notes.where((n) => !n.isDeleted).toList()..sort(_sortNotes);
  }

  static Future<Note?> getNoteById(String id) async {
    await init();
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Note>> getPinnedNotes() async {
    await init();
    return _notes.where((n) => n.isPinned && !n.isDeleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<List<Note>> getFavoriteNotes() async {
    await init();
    return _notes.where((n) => n.isFavorite && !n.isDeleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<List<Note>> searchNotes(String query) async {
    await init();
    final searchTerm = query.toLowerCase().trim();
    if (searchTerm.isEmpty) return getAllNotes();
    final filtered = _notes
        .where((n) =>
            !n.isDeleted &&
            (n.title.toLowerCase().contains(searchTerm) ||
                n.content.toLowerCase().contains(searchTerm) ||
                n.tags.any((t) => t.toLowerCase().contains(searchTerm))))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  static Future<int> getNotesCount() async {
    await init();
    return _notes.where((n) => !n.isDeleted).length;
  }

  static Future<List<Note>> getNotesByCategory(String category) async {
    await init();
    return _notes
        .where((n) => !n.isDeleted && n.category == category)
        .toList()
      ..sort(_sortNotes);
  }

  static Future<List<Note>> getDeletedNotes() async {
    await init();
    return _notes.where((n) => n.isDeleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ─── Mutations ────────────────────────────────────────────────────────────

  /// Insert a new note and create an initial version snapshot.
  static Future<int> insertNote(Note note) async {
    await init();
    _notes.add(note);
    await _save();
    // Create first version snapshot
    await saveVersion(note);
    return 1;
  }

  /// Update an existing note. Saves a version snapshot BEFORE the update
  /// so version history always reflects the previous state.
  static Future<int> updateNote(Note note) async {
    await init();
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return 0;

    // Snapshot the CURRENT (pre-update) state as a version entry
    final previousNote = _notes[index];
    if (previousNote.content != note.content || previousNote.title != note.title) {
      await saveVersion(previousNote);
    }

    _notes[index] = note;
    await _save();
    return 1;
  }

  /// Soft-delete a note (sets isDeleted = true).
  static Future<int> deleteNote(String id) async {
    await init();
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return 0;
    _notes[index] = _notes[index].copyWith(isDeleted: true);
    await _save();
    return 1;
  }

  /// Permanently removes the note record (used in trash emptying).
  /// NOTE: version history deletion is handled by the caller (NoteService.permanentlyDeleteNote)
  /// to avoid double-deleting when this is called directly from TrashScreen.
  static Future<int> permanentlyDeleteNote(String id) async {
    await init();
    final initialLength = _notes.length;
    _notes.removeWhere((n) => n.id == id);
    if (_notes.length != initialLength) {
      await _save();
    }
    return initialLength - _notes.length;
  }

  static Future<void> restoreNote(String id) async {
    await init();
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(isDeleted: false);
      await _save();
    }
  }

  // ─── Version History ──────────────────────────────────────────────────────

  static const int _maxVersionsPerNote = 10;

  /// Saves a snapshot of [note] as a new version entry.
  static Future<void> saveVersion(Note note) async {
    try {
      final file = await _versionsFile;
      Map<String, dynamic> allVersions = {};
      if (await file.exists()) {
        final content = await file.readAsString();
        allVersions = Map<String, dynamic>.from(jsonDecode(content) as Map);
      }

      final List<dynamic> noteVersions = List.from(allVersions[note.id] ?? []);
      noteVersions.add({
        ...note.toJson(),
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Trim to max
      if (noteVersions.length > _maxVersionsPerNote) {
        noteVersions.removeRange(0, noteVersions.length - _maxVersionsPerNote);
      }

      allVersions[note.id] = noteVersions;
      await file.writeAsString(jsonEncode(allVersions));
    } catch (e) {
      debugPrint('DatabaseService.saveVersion error: $e');
    }
  }

  /// Returns historical [Note] snapshots for [noteId], newest first.
  static Future<List<Note>> getVersions(String noteId) async {
    try {
      final file = await _versionsFile;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final allVersions = Map<String, dynamic>.from(jsonDecode(content) as Map);
      final List<dynamic> raw = (allVersions[noteId] as List?) ?? [];
      final versions = raw
          .whereType<Map<String, dynamic>>()
          .map((v) => Note.fromJson(v))
          .toList();
      return versions.reversed.toList(); // Newest first
    } catch (e) {
      debugPrint('DatabaseService.getVersions error: $e');
      return [];
    }
  }

  static Future<void> deleteVersions(String noteId) async {
    try {
      final file = await _versionsFile;
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final allVersions = Map<String, dynamic>.from(jsonDecode(content) as Map);
      allVersions.remove(noteId);
      await file.writeAsString(jsonEncode(allVersions));
    } catch (e) {
      debugPrint('DatabaseService.deleteVersions error: $e');
    }
  }
}
