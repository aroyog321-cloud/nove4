import 'package:uuid/uuid.dart';
import '../models/note.dart';
import 'database_service.dart';

class NoteService {
  static const _uuid = Uuid();

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static double _calculateReadTime(String content) {
    final wordCount = _calculateWordCount(content);
    if (wordCount == 0) return 0.0;
    return (wordCount / 200).clamp(0.5, double.infinity);
  }

  static int _calculateWordCount(String content) {
    return content
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;
  }

  /// Extracts #hashtags from note content
  static List<String> _extractTags(String content) {
    final regex = RegExp(r'#(\w+)');
    return regex
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Extracts the first non-empty line as a title, truncated at 100 chars
  static String _extractTitle(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty);
    if (lines.isEmpty) return 'Untitled';
    final first = lines.first
        .replaceAll(RegExp(r'^#{1,6}\s*'), '') // strip markdown headers
        .trim();
    if (first.isEmpty) return 'Untitled';
    return first.length > 100 ? '${first.substring(0, 97)}...' : first;
  }

  // ─── Queries ──────────────────────────────────────────────────────────────

  static Future<List<Note>> getAllNotes() => DatabaseService.getAllNotes();

  static Future<Note?> getNoteById(String id) => DatabaseService.getNoteById(id);

  static Future<List<Note>> getPinnedNotes() => DatabaseService.getPinnedNotes();

  static Future<List<Note>> getFavoriteNotes() => DatabaseService.getFavoriteNotes();

  static Future<List<Note>> searchNotes(String query) async {
    if (query.trim().isEmpty) return getAllNotes();
    return DatabaseService.searchNotes(query);
  }

  static Future<int> getNotesCount() => DatabaseService.getNotesCount();

  static Future<List<Note>> getNotesByCategory(String category) =>
      DatabaseService.getNotesByCategory(category);

  // ─── Create ───────────────────────────────────────────────────────────────

  static Future<Note> createNote(
    String content, {
    String? titleOverride,
    String? category,
    String colorLabel = '#FFFFFF',
    bool isPinned = false,
    bool isFavorite = false,
    int? reminder,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'note_${now}_${_uuid.v4().substring(0, 8)}';

    final resolvedTitle = (titleOverride != null && titleOverride.trim().isNotEmpty)
        ? titleOverride.trim()
        : _extractTitle(content);

    final wordCount = _calculateWordCount(content);

    final note = Note(
      id: id,
      title: resolvedTitle,
      content: content,
      category: category,
      colorLabel: colorLabel,
      isPinned: isPinned,
      isFavorite: isFavorite,
      createdAt: now,
      updatedAt: now,
      wordCount: wordCount,
      charCount: content.length,
      readTimeMinutes: _calculateReadTime(content),
      reminder: reminder,
      tags: _extractTags(content),
    );

    await DatabaseService.insertNote(note);
    return note;
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  static Future<Note?> updateNote(
    String id, {
    String? title,
    String? content,
    String? category,
    String? colorLabel,
    bool? isPinned,
    bool? isFavorite,
    int? reminder,
  }) async {
    final existing = await DatabaseService.getNoteById(id);
    if (existing == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final newContent = content ?? existing.content;

    final resolvedTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : _extractTitle(newContent);

    final wordCount = _calculateWordCount(newContent);

    final updatedNote = existing.copyWith(
      title: resolvedTitle,
      content: newContent,
      category: category ?? existing.category,
      colorLabel: colorLabel ?? existing.colorLabel,
      isPinned: isPinned ?? existing.isPinned,
      isFavorite: isFavorite ?? existing.isFavorite,
      updatedAt: now,
      wordCount: wordCount,
      charCount: newContent.length,
      readTimeMinutes: _calculateReadTime(newContent),
      reminder: reminder ?? existing.reminder,
      tags: _extractTags(newContent),
    );

    await DatabaseService.updateNote(updatedNote);
    return updatedNote;
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  static Future<bool> deleteNote(String id) async {
    final affected = await DatabaseService.deleteNote(id);
    if (affected > 0) {
      await DatabaseService.deleteVersions(id);
    }
    return affected > 0;
  }

  /// Restores a soft-deleted note from trash back to the active note list.
  static Future<void> restoreNote(String id) =>
      DatabaseService.restoreNote(id);

  static Future<void> clearAll() async {
    final notes = await getAllNotes();
    for (final note in notes) {
      await deleteNote(note.id);
    }
  }

  // ─── Toggles ──────────────────────────────────────────────────────────────

  static Future<Note?> togglePin(String id) async {
    final note = await DatabaseService.getNoteById(id);
    if (note == null) return null;
    return updateNote(id, isPinned: !note.isPinned);
  }

  static Future<Note?> toggleFavorite(String id) async {
    final note = await DatabaseService.getNoteById(id);
    if (note == null) return null;
    return updateNote(id, isFavorite: !note.isFavorite);
  }
}
