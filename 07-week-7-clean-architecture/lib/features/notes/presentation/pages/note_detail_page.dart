import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';

/// Halaman detail catatan.
///
/// Membaca catatan dari repository lewat `noteByIdProvider`, **bukan** dari
/// state halaman daftar — sehingga deep link `/note/:id` tetap bekerja
/// walaupun halaman daftar belum pernah dibuka.
class NoteDetailPage extends ConsumerStatefulWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final int? noteId;

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  /// Catatan yang isinya sudah dimuat ke controller.
  ///
  /// `build()` bisa dijalankan berkali-kali; tanpa penanda ini, setiap rebuild
  /// akan menimpa ketikan user dengan nilai dari database.
  int? _loadedId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteId = widget.noteId;
    if (noteId == null) {
      return const Scaffold(
        body: Center(child: Text('Catatan tidak ditemukan')),
      );
    }

    final noteAsync = ref.watch(noteByIdProvider(noteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail catatan'),
        actions: [
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: noteAsync.value == null ? null : () => _delete(noteId),
          ),
          IconButton(
            tooltip: 'Simpan',
            icon: const Icon(Icons.save),
            onPressed: noteAsync.value == null ? null : () => _save(noteId),
          ),
        ],
      ),
      body: noteAsync.when(
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Catatan tidak ditemukan'));
          }
          if (_loadedId != note.id) {
            _loadedId = note.id;
            _titleController.text = note.title;
            _bodyController.text = note.body;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: note.dirty
                    ? const DirtyBadge()
                    : const Text(
                        'sudah tersinkron',
                        style: TextStyle(fontSize: 11),
                      ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Isi catatan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Menyimpan hanya mengubah data lokal dan menandai catatan '
                'sebagai belum tersinkron. Tekan Sync di halaman daftar untuk '
                'mengirim perubahan.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }

  Future<void> _save(int id) async {
    // Diambil SEBELUM await: setelah await, context bisa sudah tidak valid.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final note = ref.read(noteByIdProvider(id)).value;
    if (note == null) return;

    // Aturan `updatedAt = now` dan `dirty = true` sekarang ada di use case
    // UpdateNote, bukan di widget ini.
    await ref
        .read(notesProvider.notifier)
        .updateNote(
          note: note,
          title: _titleController.text,
          body: _bodyController.text,
        );

    // Dua provider berbeda: notesProvider (daftar) dan noteByIdProvider (detail).
    ref.invalidate(noteByIdProvider(id));

    messenger.showSnackBar(
      const SnackBar(content: Text('Tersimpan lokal - masih menunggu sync')),
    );
    router.pop();
  }

  Future<void> _delete(int id) async {
    final router = GoRouter.of(context);
    await ref.read(notesProvider.notifier).remove(id);
    ref.invalidate(noteByIdProvider(id));
    router.pop();
  }
}
