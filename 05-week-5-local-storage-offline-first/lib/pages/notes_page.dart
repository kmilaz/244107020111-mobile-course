import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import '../data/providers.dart';
import 'settings_page.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);
    final posts = ref.watch(postsProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          Center(child: _DirtyChip(count: dirtyCount.value ?? 0)),
          IconButton(
            tooltip: 'Sync',
            icon: const Icon(Icons.sync),
            onPressed: () => _sync(context, ref),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
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
                        return _NoteRow(
                          note: note,
                          onDelete: id == null
                              ? null
                              : () => ref
                                  .read(notesProvider.notifier)
                                  .remove(id),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Error membaca catatan: $error')),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Posts (cache-first)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_postsLabel(posts),
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Muat ulang',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(postsProvider.notifier).load(),
                ),
              ],
            ),
          ),
          if (posts.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: posts.posts.isEmpty
                ? const Center(child: Text('Belum ada posts. Tekan muat ulang.'))
                : ListView.builder(
                    itemCount: posts.posts.length,
                    itemBuilder: (context, index) {
                      final post = posts.posts[index];
                      return ListTile(
                        dense: true,
                        title: Text(post.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(post.body,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
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

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, this.onDelete});

  final Note note;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Row(
        children: [
          if (note.dirty) const _DirtyBadge(),
          if (note.dirty) const SizedBox(width: 6),
          Expanded(
            child: Text(
              note.body.isEmpty ? _formatTime(note.updatedAt) : note.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: onDelete == null
          ? null
          : IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
    );
  }
}

class _DirtyBadge extends StatelessWidget {
  const _DirtyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'belum tersinkron',
        style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
      ),
    );
  }
}

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

String _formatTime(DateTime time) {
  final minute = time.minute.toString().padLeft(2, '0');
  return '${time.day}/${time.month} ${time.hour}:$minute';
}

String _postsLabel(PostsState state) {
  final cachedAt = state.lastCachedAt;
  final stamp = cachedAt == null
      ? ''
      : ' ${cachedAt.day}/${cachedAt.month} '
          '${cachedAt.hour}:${cachedAt.minute.toString().padLeft(2, '0')}';

  final base = switch (state.source) {
    PostsSource.none => 'belum dimuat',
    PostsSource.cache => 'dari cache$stamp',
    PostsSource.network => 'dari jaringan$stamp',
  };

  return state.error != null ? '$base - gagal refresh' : base;
}