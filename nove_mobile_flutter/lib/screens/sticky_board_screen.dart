import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import '../theme/tokens.dart';
import '../models/sticky_note.dart';
import '../providers/sticky_notes_provider.dart';
import '../widgets/app_link_picker.dart';

// ─── Custom Clippers & Painters ─────────────────────────────────────────────

class PeeledCornerClipper extends CustomClipper<Path> {
  final double foldSize;
  PeeledCornerClipper({this.foldSize = 24.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - foldSize);
    path.lineTo(size.width - foldSize, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class PeeledCornerPainter extends CustomPainter {
  final double foldSize;
  PeeledCornerPainter({this.foldSize = 24.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, size.height - foldSize);
    path.lineTo(size.width - foldSize, size.height - foldSize);
    path.lineTo(size.width - foldSize, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class StickyBoardScreen extends ConsumerStatefulWidget {
  const StickyBoardScreen({super.key});

  @override
  ConsumerState<StickyBoardScreen> createState() => _StickyBoardScreenState();
}

class _StickyBoardScreenState extends ConsumerState<StickyBoardScreen> {
  final _inputController = TextEditingController();
  StickyColor _selectedColor = StickyColor.yellow;
  Timer? _overlayCheckTimer;

  final double _gridSnapSize = 32.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stickyNotesProvider.notifier).loadNotes();
    });

    _overlayCheckTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      final poppedNote = ref.read(poppedOutNoteProvider);
      if (poppedNote != null) {
        try {
          final isActive = await FlutterOverlayWindow.isActive();
          if (!isActive) {
            ref.read(poppedOutNoteProvider.notifier).state = null;
          }
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _overlayCheckTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _addNote() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      final screenWidth = MediaQuery.of(context).size.width;
      final pos = _getUnoccupiedGridPosition(screenWidth);
      ref
          .read(stickyNotesProvider.notifier)
          .createNote(text, _selectedColor, '', pos.dx, pos.dy);
      _inputController.clear();
      HapticFeedback.mediumImpact();
    }
  }

  void _deleteNote(String id) {
    ref.read(stickyNotesProvider.notifier).moveToTrash(id);
  }

  void _updateNoteContent(String id, String content) {
    ref.read(stickyNotesProvider.notifier).updateNoteContent(id, content);
  }

  void _togglePin(String id) {
    HapticFeedback.lightImpact();
    ref.read(stickyNotesProvider.notifier).togglePin(id);
  }

  Color _getNoteColor(StickyColor color) {
    switch (color) {
      case StickyColor.yellow:
        return const Color(0xFFF5C842);
      case StickyColor.pink:
        return const Color(0xFFF2C2D8);
      case StickyColor.green:
        return const Color(0xFFC5EDBE);
      case StickyColor.blue:
        return const Color(0xFFB3E5FC);
    }
  }

  void _minimizeNote(StickyNote note) async {
    final poppedNote = ref.read(poppedOutNoteProvider);

    if (poppedNote != null && poppedNote.id != note.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Android only allows 1 floating note at a time. Please restore your active note first.')),
        );
      }
      return;
    }

    ref.read(poppedOutNoteProvider.notifier).state = note;

    try {
      bool hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        bool? requested = await FlutterOverlayWindow.requestPermission();
        if (requested != true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Overlay Permission is required to float notes.')),
            );
          }
          return;
        }
      }

      final data = jsonEncode({
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'color': _getNoteColor(note.color).toARGB32(),
        'isBubble': true,
      });

      bool isActive = false;
      try {
        isActive = await FlutterOverlayWindow.isActive();
      } catch (_) {
        isActive = false;
      }

      if (isActive) {
        await FlutterOverlayWindow.resizeOverlay(100, 100, true);
        await FlutterOverlayWindow.shareData("note:$data");
      } else {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          height: 100,
          width: 100,
          alignment: OverlayAlignment.centerRight,
        );
        await Future.delayed(const Duration(milliseconds: 400));
        await FlutterOverlayWindow.shareData("note:$data");
      }
    } catch (e) {
      debugPrint('Overlay blocked or crashed: $e');
    }
  }

  void _showAppPicker(BuildContext context, StickyNote note) async {
    if (note.linkedApp != null) {
      HapticFeedback.lightImpact();
      ref.read(stickyNotesProvider.notifier).unlinkApp(note.id);
      return;
    }

    showAppLinkPicker(
      context: context,
      onAppSelected: (app) {
        ref
            .read(stickyNotesProvider.notifier)
            .linkApp(note.id, app.packageName, app.name);
      },
    );
  }

  Offset _snapToGrid(Offset position) {
    double snappedX = (position.dx / _gridSnapSize).round() * _gridSnapSize;
    double snappedY = (position.dy / _gridSnapSize).round() * _gridSnapSize;
    return Offset(math.max(0, snappedX), math.max(0, snappedY));
  }

  Offset _getGridPosition(int index, double screenWidth) {
    const double cardWidth = 160.0;
    const double cardHeight = 184.0;
    const double gapX = 16.0;
    const double gapY = 20.0;
    const double minPadding = 16.0;

    final double availableWidth = screenWidth - (minPadding * 2);
    int columns = ((availableWidth + gapX) / (cardWidth + gapX)).floor();
    if (columns < 1) columns = 1;

    final double totalGridWidth = (columns * cardWidth) + ((columns - 1) * gapX);
    final double horizontalOffset = (screenWidth - totalGridWidth) / 2;

    final int col = index % columns;
    final int row = index ~/ columns;

    const double topPadding = 16.0;

    final double x = horizontalOffset + col * (cardWidth + gapX);
    final double y = topPadding + row * (cardHeight + gapY);

    return Offset(x, y);
  }

  void _arrangeNotes(List<StickyNote> visibleNotes, double screenWidth) {
    HapticFeedback.mediumImpact();
    for (int i = 0; i < visibleNotes.length; i++) {
      final pos = _getGridPosition(i, screenWidth);
      ref
          .read(stickyNotesProvider.notifier)
          .updateNotePosition(visibleNotes[i].id, pos.dx, pos.dy);
    }
  }

  Offset _getUnoccupiedGridPosition(
    double screenWidth, [
    List<StickyNote>? existing,
  ]) {
    final List<StickyNote> notes = existing ?? ref.read(stickyNotesProvider);
    for (int i = 0; i < 1000; i++) {
      final pos = _getGridPosition(i, screenWidth);
      bool occupied = false;
      for (final n in notes) {
        if ((n.x - pos.dx).abs() < 8 && (n.y - pos.dy).abs() < 8) {
          occupied = true;
          break;
        }
      }
      if (!occupied) return pos;
    }
    return _getGridPosition(0, screenWidth);
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(stickyNotesProvider);
    final poppedNote = ref.watch(poppedOutNoteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final notifier = ref.read(stickyNotesProvider.notifier);
    final visibleNotes =
        allNotes.where((n) => n.id != poppedNote?.id).toList();
    visibleNotes.sort((a, b) {
      final aPinned = notifier.isPinned(a.id);
      final bPinned = notifier.isPinned(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: NoveColors.bg(context),
      body: Stack(
        children: [
          // ── Dot grid background fills the whole screen ─────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(isDark: isDark, spacing: _gridSnapSize),
            ),
          ),

          // ── Scrollable sticky notes area ───────────────────────────────
          Positioned.fill(
            child: visibleNotes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 140),
                      child: Text(
                        'No sticky notes yet.\nAdd one below!',
                        textAlign: TextAlign.center,
                        style: NoveTypography.dmsans(
                          style: TextStyle(
                            fontSize: 16,
                            color: NoveColors.mutedText(context),
                          ),
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 130, bottom: 120),
                    child: SizedBox(
                      height: math.max(
                          1000,
                          (visibleNotes.length / 2).ceil() * 200.0 + 100),
                      width: double.infinity,
                      child: Stack(
                        children: visibleNotes.asMap().entries.map((entry) {
                          final note = entry.value;
                          final isPinned = notifier.isPinned(note.id);
                          final screenWidth = MediaQuery.of(context).size.width;

                          Offset pos;
                          if (note.x == 0 && note.y == 0) {
                            pos = _getUnoccupiedGridPosition(
                                screenWidth, visibleNotes);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                notifier.updateNotePosition(
                                    note.id, pos.dx, pos.dy);
                              }
                            });
                          } else {
                            pos = Offset(note.x, note.y);
                          }

                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            key: ValueKey(note.id),
                            left: pos.dx,
                            top: pos.dy,
                            child: SizedBox(
                              width: 160,
                              height: 184,
                              child: _StickyCard(
                                note: note,
                                isPinned: isPinned,
                                onDelete: () => _deleteNote(note.id),
                                onMinimize: () => _minimizeNote(note),
                                onTogglePin: () => _togglePin(note.id),
                                onLinkApp: () =>
                                    _showAppPicker(context, note),
                                onContentChanged: (newText) =>
                                    _updateNoteContent(note.id, newText),
                                onDragUpdate: (details) {
                                  notifier.updateNotePosition(
                                    note.id,
                                    pos.dx + details.delta.dx,
                                    pos.dy + details.delta.dy,
                                  );
                                },
                                onDragEnd: () {
                                  HapticFeedback.lightImpact();
                                  final snapped = _snapToGrid(pos);
                                  notifier.updateNotePosition(
                                      note.id, snapped.dx, snapped.dy);
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),

          // ── Glassmorphism header — always on top ───────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _GlassHeader(
              isDark: isDark,
              // FIX (Bug 3 — sticky_board): noteCount was defined on _GlassHeader
              // but never passed at this call site, so the note-count badge was
              // permanently hidden. Pass visibleNotes.length so it renders correctly.
              noteCount: visibleNotes.length,
              onRestore: () async {
                try {
                  await FlutterOverlayWindow.closeOverlay();
                } catch (_) {}
                ref.read(poppedOutNoteProvider.notifier).state = null;
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Floating note restored.')),
                );
              },
              onArrange: () => _arrangeNotes(
                  visibleNotes, MediaQuery.of(context).size.width),
            ),
          ),
        ],
      ),
      bottomSheet: _InputBar(
        controller: _inputController,
        selectedColor: _selectedColor,
        isDark: isDark,
        onColorChanged: (c) {
          HapticFeedback.selectionClick();
          setState(() => _selectedColor = c);
        },
        onAdd: _addNote,
      ),
    );
  }
}

// ─── Glassmorphism Header ─────────────────────────────────────────────────────

class _GlassHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRestore;
  final VoidCallback onArrange;
  final int noteCount;

  const _GlassHeader({
    required this.isDark,
    required this.onRestore,
    required this.onArrange,
    this.noteCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1E1C15).withValues(alpha: 0.88),
                      const Color(0xFF171510).withValues(alpha: 0.78),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.78),
                      const Color(0xFFFDF8F0).withValues(alpha: 0.68),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : NoveColors.terracotta.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Terracotta icon pill ─────────────────────────────────
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [NoveColors.terracottaLight, NoveColors.terracottaDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: NoveColors.terracotta.withValues(alpha: 0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              // ── Title block ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sticky Board',
                      style: NoveTypography.lora(
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: isDark ? NoveColors.cream : NoveColors.warmGray900,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        // Live dot
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: NoveColors.terracotta,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: NoveColors.terracotta.withValues(alpha: 0.55),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'BRAINSTORM ARENA',
                          style: NoveTypography.dmsans(
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: NoveColors.mutedText(context),
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Note count badge ─────────────────────────────────────
              if (noteCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: NoveColors.terracotta.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(NoveRadii.full),
                    border: Border.all(
                      color: NoveColors.terracotta.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sticky_note_2_rounded, size: 11, color: NoveColors.terracotta),
                      const SizedBox(width: 4),
                      Text(
                        '$noteCount',
                        style: NoveTypography.dmsans(
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: NoveColors.terracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Glass icon buttons ──────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GlassIconButton(
                    icon: Icons.settings_backup_restore_rounded,
                    tooltip: 'Restore Floating Note',
                    isDark: isDark,
                    onTap: onRestore,
                  ),
                  const SizedBox(width: 8),
                  _GlassIconButton(
                    icon: Icons.grid_view_rounded,
                    tooltip: 'Arrange Board',
                    isDark: isDark,
                    onTap: onArrange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glass icon button ─────────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: NoveColors.terracotta.withValues(alpha: 0.12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.90),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: isDark ? NoveColors.cream : NoveColors.warmGray700,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dot Grid Painter ────────────────────────────────────────────────────────

class DotGridPainter extends CustomPainter {
  final bool isDark;
  final double spacing;
  DotGridPainter({required this.isDark, this.spacing = 32.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? NoveColors.warmGray800.withValues(alpha: 0.5)
          : NoveColors.warmGray300.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ─── Sticky Card ─────────────────────────────────────────────────────────────

class _StickyCard extends StatefulWidget {
  final StickyNote note;
  final bool isPinned;
  final VoidCallback onDelete;
  final VoidCallback onMinimize;
  final VoidCallback onTogglePin;
  final VoidCallback onLinkApp;
  final ValueChanged<String> onContentChanged;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnd;

  const _StickyCard({
    required this.note,
    required this.isPinned,
    required this.onDelete,
    required this.onMinimize,
    required this.onTogglePin,
    required this.onLinkApp,
    required this.onContentChanged,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<_StickyCard> createState() => _StickyCardState();
}

class _StickyCardState extends State<_StickyCard> {
  late TextEditingController _textController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.note.color) {
      case StickyColor.yellow:
        return const Color(0xFFF5C842);
      case StickyColor.pink:
        return const Color(0xFFF2C2D8);
      case StickyColor.green:
        return const Color(0xFFC5EDBE);
      case StickyColor.blue:
        return const Color(0xFFB3E5FC);
    }
  }

  void _confirmDelete() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NoveColors.cardBg(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Move to Trash',
          style: TextStyle(
            color: NoveColors.primaryText(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Move this sticky note to the trash bin?',
          style: TextStyle(color: NoveColors.secondaryText(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(color: NoveColors.primaryText(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDelete();
            },
            child: const Text('Trash',
                style: TextStyle(
                    color: NoveColors.error,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black54,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double foldSize = 24.0;

    return AnimatedScale(
      scale: _isDragging ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedRotation(
        turns: _isDragging ? 0.02 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF31312D)
                    .withValues(alpha: _isDragging ? 0.30 : 0.15),
                blurRadius: _isDragging ? 24 : 16,
                offset: Offset(0, _isDragging ? 12 : 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Main sticky body ────────────────────────────────────
              ClipPath(
                clipper: PeeledCornerClipper(foldSize: foldSize),
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Single header row ───────────────────────────
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            // Drag handle — 28px
                            GestureDetector(
                              onPanStart: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _isDragging = true);
                              },
                              onPanEnd: (_) {
                                setState(() => _isDragging = false);
                                widget.onDragEnd();
                              },
                              onPanCancel: () {
                                setState(() => _isDragging = false);
                                widget.onDragEnd();
                              },
                              onPanUpdate: widget.onDragUpdate,
                              child: const SizedBox(
                                width: 28,
                                height: 24,
                                child: Icon(Icons.drag_indicator,
                                    size: 18, color: Colors.black38),
                              ),
                            ),

                            // All 4 action icons — 4 × 24px = 96px
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _iconBtn(
                                  icon: widget.note.linkedApp != null
                                      ? Icons.link
                                      : Icons.link_off,
                                  onTap: widget.onLinkApp,
                                  color: widget.note.linkedApp != null
                                      ? Colors.blue
                                      : Colors.black45,
                                  tooltip:
                                      widget.note.linkedApp != null
                                          ? 'Unlink app'
                                          : 'Link app',
                                ),
                                _iconBtn(
                                  icon: Icons.open_in_new,
                                  onTap: widget.onMinimize,
                                  color: Colors.black54,
                                  tooltip: 'Float note',
                                ),
                                _iconBtn(
                                  icon: widget.isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  onTap: widget.onTogglePin,
                                  color: widget.isPinned
                                      ? NoveColors.terracotta
                                      : Colors.black54,
                                  tooltip: widget.isPinned
                                      ? 'Unpin'
                                      : 'Pin',
                                ),
                                _iconBtn(
                                  icon: Icons.delete_outline,
                                  onTap: _confirmDelete,
                                  color: Colors.black45,
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // ── Optional title ──────────────────────────────
                        if (widget.note.title.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              widget.note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NoveTypography.dmsans(
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C1C18),
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),

                        // ── Content text field ──────────────────────────
                        Expanded(
                          child: TextFormField(
                            controller: _textController,
                            onChanged: widget.onContentChanged,
                            maxLines: null,
                            expands: true,
                            style: NoveTypography.caveat(
                              style: const TextStyle(
                                fontSize: 21,
                                height: 1.2,
                                color: Color(0xCC1C1C18),
                              ),
                            ),
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              hintText: 'Write here...',
                              hintStyle:
                                  TextStyle(color: Colors.black26),
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Peeled corner shadow painter ────────────────────────
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: PeeledCornerPainter(foldSize: foldSize),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Input Bar ───────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final StickyColor selectedColor;
  final ValueChanged<StickyColor> onColorChanged;
  final VoidCallback onAdd;
  final bool isDark;

  const _InputBar({
    required this.controller,
    required this.selectedColor,
    required this.onColorChanged,
    required this.onAdd,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = {
      StickyColor.yellow: const Color(0xFFF5C842),
      StickyColor.pink: const Color(0xFFF2C2D8),
      StickyColor.green: const Color(0xFFC5EDBE),
      StickyColor.blue: const Color(0xFFB3E5FC),
    };

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 90),
          decoration: BoxDecoration(
            color: NoveColors.cardBg(context).withValues(alpha: 0.82),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? NoveColors.cardBorder(context)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Row(
                children: colors.entries.map((e) {
                  final isSelected = selectedColor == e.key;
                  return GestureDetector(
                    onTap: () => onColorChanged(e.key),
                    child: AnimatedContainer(
                      duration: NoveAnimation.fast,
                      margin: const EdgeInsets.only(right: 6),
                      width: isSelected ? 26 : 22,
                      height: isSelected ? 26 : 22,
                      decoration: BoxDecoration(
                        color: e.value,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? NoveColors.terracotta
                              : (isDark ? Colors.transparent : Colors.white),
                          width: isSelected ? 2.5 : 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: e.value.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: NoveColors.primaryText(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Title (optional)...',
                    hintStyle: TextStyle(color: NoveColors.mutedText(context)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: NoveShadows.ctaGlow(),
                ),
                child: ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NoveColors.terracotta,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}