import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import 'note_service.dart';

const _uuid = Uuid();
const _seedKey = 'nove_seed_done_v1';

/// Inserts the welcome note and two sample sticky notes exactly once —
/// the very first time the app is launched on a fresh install.
class SeedService {
  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seedKey) == true) return; // already seeded

    await _seedNote();
    await _seedStickyNotes(prefs);

    await prefs.setBool(_seedKey, true);
  }

  // ─── Default Note ─────────────────────────────────────────────────────────

  static Future<void> _seedNote() async {
    const content = '''# Welcome to NOVE 👋

NOVE is your calm, distraction-free space for writing, thinking, and organising ideas.

---

## ✨ What you can do here

**Write freely** — tap the **+** button on the Notes screen to start a new note. NOVE auto-saves every 3 seconds so you never lose a thought.

**Format with Markdown** — use the toolbar at the bottom of the editor:
- **Bold**, _italic_, ~~strikethrough~~
- # Headings, • Bullet lists, ☐ To-do items
- > Blockquotes and `code`

**Slash commands** — type **/** at the start of a line to pick a block type instantly.

**WikiLinks** — type **[[** to link this note to another note.

---

## 📌 Organise your notes

- **Pin** a note so it always stays at the top
- **Star** it to add it to your Favourites
- Assign a **Category** (Work, Ideas, Personal…) and filter from the home screen
- Add **#hashtags** anywhere in your text — they become searchable tags automatically

---

## 🗂 Sticky Board

Tap **Board** in the bottom bar to open the Sticky Board — a freeform canvas where you can drag colourful sticky notes around, link them to apps, and even float one on top of any other app as a bubble.

---

## 🔒 Privacy first

Everything lives on your device. Nothing is ever uploaded to a server.

---

_Happy writing!_  
**— The NOVE Team**
''';

    await NoteService.createNote(
      content,
      titleOverride: 'Welcome to NOVE 👋',
      colorLabel: '#E8F5E9',
      category: 'Ideas',
      isPinned: true,
    );
  }

  // ─── Default Sticky Notes ─────────────────────────────────────────────────

  static Future<void> _seedStickyNotes(SharedPreferences prefs) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final sticky1 = {
      'id': 'sticky_${now}_${_uuid.v4().substring(0, 6)}',
      'title': 'Try the Sticky Board!',
      'content':
          'Drag me around the canvas. Tap the ⊞ button to arrange all notes in a grid.',
      'color': 'yellow',
      'created_at': now,
      'linked_app': null,
      'x': 24.0,
      'y': 16.0,
      'is_deleted': 0,
    };

    final sticky2 = {
      'id': 'sticky_${now + 1}_${_uuid.v4().substring(0, 6)}',
      'title': 'Float me on screen 🫧',
      'content':
          'Tap the bubble icon on any sticky to float it over other apps — even while you browse!',
      'color': 'green',
      'created_at': now + 1,
      'linked_app': null,
      'x': 200.0,
      'y': 16.0,
      'is_deleted': 0,
    };

    // Sticky notes are stored as JSON in SharedPreferences under 'sticky_notes_v1'
    const stickyKey = 'sticky_notes_v1';
    final existing = prefs.getString(stickyKey);
    final List<dynamic> list =
        existing != null ? (jsonDecode(existing) as List) : [];

    list.insert(0, sticky2);
    list.insert(0, sticky1);

    await prefs.setString(stickyKey, jsonEncode(list));
  }
}
