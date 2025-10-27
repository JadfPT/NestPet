import 'package:flutter/material.dart';

import 'note.dart';
import 'notes_dao.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _dao = NotesDao();
  List<Note> _notes = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await _dao.getAll(query: _search);
    setState(() => _notes = notes);
  }

  Future<void> _addOrEdit([Note? note]) async {
    final result = await showDialog<Note>(
      context: context,
      builder: (_) => _NoteDialog(note: note),
    );
    if (result != null) {
      if (result.id == null) {
        await _dao.insert(result);
      } else {
        await _dao.update(result);
      }
      await _load();
    }
  }

  Future<void> _delete(Note n) async {
    if (n.id != null) {
      await _dao.delete(n.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Pesquisar…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              _search = v;
              _load();
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _notes.length,
            itemBuilder: (_, i) {
              final n = _notes[i];
              return Dismissible(
                key: ValueKey(n.id ?? n.title + n.createdAt.toIso8601String()),
                background: Container(color: Colors.redAccent),
                onDismissed: (_) => _delete(n),
                child: ListTile(
                  title: Text(n.title),
                  subtitle: Text(
                    n.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _fmt(n.createdAt),
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  onTap: () => _addOrEdit(n),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FloatingActionButton.extended(
            onPressed: () => _addOrEdit(),
            icon: const Icon(Icons.add),
            label: const Text('Nova nota'),
          ),
        ),
      ],
    );
  }
}

String _fmt(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _NoteDialog extends StatefulWidget {
  final Note? note;
  const _NoteDialog({this.note});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _title;
  late final TextEditingController _content;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _content = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Nova nota' : 'Editar nota'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _content,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Conteúdo'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final now = DateTime.now();
            final n = Note(
              id: widget.note?.id,
              title: _title.text.trim(),
              content: _content.text.trim(),
              createdAt: widget.note?.createdAt ?? now,
            );
            Navigator.pop(context, n);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
