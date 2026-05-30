import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/sticky_note.dart';
import '../../ui/widgets/empty_state.dart';
import 'notes_store.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotesStore>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Notes'),
          actions: [
            IconButton(
              tooltip: 'Add note',
              onPressed: () => _openCreate(context),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (store.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (store.notes.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              title: 'No sticky notes',
              subtitle: 'Create a daily plan and export it as an image.',
              action: FilledButton.icon(
                onPressed: () => _openCreate(context),
                icon: const Icon(Icons.add),
                label: const Text('Create note'),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList.separated(
              itemCount: store.notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _NoteCard(note: store.notes[i]),
            ),
          ),
      ],
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NoteEditorSheet(),
    );
  }
}

class _NoteCard extends StatefulWidget {
  const _NoteCard({required this.note});
  final StickyNote note;

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final store = context.read<NotesStore>();
    final note = widget.note;
    final bg = Color(note.style.colorHex);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sticky note',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Export PNG',
                  onPressed: () => _exportPng(context),
                  icon: const Icon(Icons.image_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete note?'),
                        content: const Text('This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await store.delete(note);
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _format(note),
                  style: TextStyle(
                    fontSize: note.style.fontSize,
                    height: 1.35,
                    color: const Color(0xFF0B0E14),
                    fontFamily: note.style.fontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(StickyNote note) {
    final content = note.content.trim();
    if (note.style.layout == 'paragraph') return content;

    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
    if (lines.length <= 1) return '• $content';
    return lines.map((l) => '• $l').join('\n');
  }

  Future<void> _exportPng(BuildContext context) async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Export not ready yet.');
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('Failed to encode PNG.');
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sticky_note_${widget.note.id}.png');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'My plan',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet();

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  final _content = TextEditingController();

  int _colorHex = 0xFFFFF3B0;
  double _fontSize = 16;
  String _layout = 'bullet';

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('New note', style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _content,
              decoration: const InputDecoration(
                labelText: 'Daily plan',
                hintText: 'Write one item per line…',
              ),
              autofocus: true,
              maxLines: 6,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Layout'),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'bullet', label: Text('Bullets')),
                    ButtonSegment(value: 'paragraph', label: Text('Paragraph')),
                  ],
                  selected: {_layout},
                  onSelectionChanged: (s) => setState(() => _layout = s.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Font size'),
                const Spacer(),
                Text(_fontSize.toStringAsFixed(0)),
              ],
            ),
            Slider(
              value: _fontSize,
              min: 12,
              max: 26,
              divisions: 14,
              onChanged: (v) => setState(() => _fontSize = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Color'),
                const Spacer(),
                _ColorDot(
                  color: const Color(0xFFFFF3B0),
                  selected: _colorHex == 0xFFFFF3B0,
                  onTap: () => setState(() => _colorHex = 0xFFFFF3B0),
                ),
                const SizedBox(width: 8),
                _ColorDot(
                  color: const Color(0xFFB8F2E6),
                  selected: _colorHex == 0xFFB8F2E6,
                  onTap: () => setState(() => _colorHex = 0xFFB8F2E6),
                ),
                const SizedBox(width: 8),
                _ColorDot(
                  color: const Color(0xFFFFC6FF),
                  selected: _colorHex == 0xFFFFC6FF,
                  onTap: () => setState(() => _colorHex = 0xFFFFC6FF),
                ),
                const SizedBox(width: 8),
                _ColorDot(
                  color: const Color(0xFFC7D2FE),
                  selected: _colorHex == 0xFFC7D2FE,
                  onTap: () => setState(() => _colorHex = 0xFFC7D2FE),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final text = _content.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note cannot be empty')),
                    );
                    return;
                  }
                  await context.read<NotesStore>().add(
                        content: text,
                        style: StickyNoteStyle(
                          colorHex: _colorHex,
                          fontSize: _fontSize,
                          fontFamily: 'Roboto',
                          layout: _layout,
                        ),
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

