import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/providers.dart';
import '../../../posts/presentation/widgets/posts_section.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          Center(child: _DirtyChip(count: dirtyCount)),
          IconButton(
            tooltip: 'Sync',
            icon: const Icon(Icons.sync),
            onPressed: () => _sync(context, ref),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNote(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            dense: true,
            title: const Text('Force offline'),
            value: forceOffline,
            onChanged: (value) =>
                ref.read(forceOfflineProvider.notifier).set(value),
          ),
          const Divider(height: 1),
          Expanded(
            child: notes.when(
              data: (items) => items.isEmpty
                  ? const Center(child: Text('Belum ada catatan'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final note = items[index];
                        final id = note.id;
                        return NoteTile(
                          note: note,
                          onTap: id == null
                              ? null
                              : () => context.push('/note/$id'),
                          onDelete: id == null
                              ? null
                              : () =>
                                    ref.read(notesProvider.notifier).remove(id),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              // Pesannya sudah ramah: layer data mengubah exception menjadi
              // Failure, dan Failure.toString() = pesannya.
              error: (error, _) => Center(child: Text('$error')),
            ),
          ),
          const Divider(height: 1),
          // Seluruh isi fitur posts ditangani widget-nya sendiri.
          const Expanded(child: PostsSection()),
        ],
      ),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    // `title` hidup di scope METHOD, bukan di dalam build(): kalau ditaruh di
    // dalam, keyboard yang muncul akan me-rebuild dialog dan mengosongkannya.
    var title = '';

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Catatan baru'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Judul catatan'),
          onChanged: (value) => title = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, title),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;
    await ref.read(notesProvider.notifier).add(title: result.trim());
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    if (ref.read(forceOfflineProvider)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Mode offline aktif - sync dilewati')),
      );
      return;
    }

    final synced = await ref.read(notesProvider.notifier).sync();
    messenger.showSnackBar(
      SnackBar(content: Text('$synced catatan tersinkron')),
    );
  }
}

/// Ringkasan antrean sync untuk seluruh daftar.
/// (Berbeda dari NoteTile, yang hanya menampilkan status SATU baris.)
class _DirtyChip extends StatelessWidget {
  const _DirtyChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(count == 0 ? 'semua tersinkron' : '$count belum sync'),
      backgroundColor: count == 0
          ? Colors.green.shade100
          : Colors.orange.shade200,
    );
  }
}
