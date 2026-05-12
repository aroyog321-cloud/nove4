/// Note model representing a note in the app
class Note {
  final String id;
  final String title;
  final String content;
  final String? category;
  final String colorLabel;
  final bool isPinned;
  final bool isFavorite;
  final int createdAt;
  final int updatedAt;
  final int wordCount;
  final int charCount;
  final double readTimeMinutes;
  final int? reminder;
  final List<String> tags;
  final bool isDeleted;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.colorLabel = '#FFFFFF',
    this.isPinned = false,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.wordCount = 0,
    this.charCount = 0,
    this.readTimeMinutes = 0.0,
    this.reminder,
    this.tags = const [],
    this.isDeleted = false,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    // Safe tag parsing: handles null, String (CSV), or List
    List<String> parseTags(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) return List<String>.from(raw.where((e) => e != null));
      if (raw is String) {
        if (raw.isEmpty) return const [];
        try {
          // Might be JSON list encoded as string
          if (raw.startsWith('[')) {
            return List<String>.from(
              (raw.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(','))
                  .where((s) => s.trim().isNotEmpty)
                  .map((s) => s.trim()),
            );
          }
        } catch (_) {}
        // Plain CSV
        return raw.split(',').where((s) => s.trim().isNotEmpty).map((s) => s.trim()).toList();
      }
      return const [];
    }

    return Note(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      category: map['category']?.toString(),
      colorLabel: map['color_label']?.toString() ?? '#FFFFFF',
      isPinned: map['is_pinned'] == 1 || map['is_pinned'] == true || map['is_pinned'] == '1',
      isFavorite: map['is_favorite'] == 1 || map['is_favorite'] == true || map['is_favorite'] == '1',
      createdAt: (map['created_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      wordCount: (map['word_count'] as num?)?.toInt() ?? 0,
      charCount: (map['char_count'] as num?)?.toInt() ?? 0,
      readTimeMinutes: (map['read_time_minutes'] as num?)?.toDouble() ?? 0.0,
      reminder: map['reminder'] != null ? (map['reminder'] as num).toInt() : null,
      tags: parseTags(map['tags']),
      isDeleted: map['is_deleted'] == 1 || map['is_deleted'] == true || map['is_deleted'] == '1',
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) => Note.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'color_label': colorLabel,
      'is_pinned': isPinned ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'word_count': wordCount,
      'char_count': charCount,
      'read_time_minutes': readTimeMinutes,
      'reminder': reminder,
      'tags': tags,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    bool clearCategory = false,
    String? colorLabel,
    bool? isPinned,
    bool? isFavorite,
    int? createdAt,
    int? updatedAt,
    int? wordCount,
    int? charCount,
    double? readTimeMinutes,
    int? reminder,
    bool clearReminder = false,
    List<String>? tags,
    bool? isDeleted,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: clearCategory ? null : (category ?? this.category),
      colorLabel: colorLabel ?? this.colorLabel,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wordCount: wordCount ?? this.wordCount,
      charCount: charCount ?? this.charCount,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      reminder: clearReminder ? null : (reminder ?? this.reminder),
      tags: tags ?? this.tags,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Note && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
