import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import 'todo_tile.dart';

// ============================================================
// TodoPage — ConsumerWidget utama untuk daftar tugas.
//
// Refactoring: menggunakan TodoTile (widget terpisah) dan
// filteredTodoProvider (logika filter terpisah dari UI).
// ============================================================

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch → berlangganan, otomatis rebuild saat todoListProvider berubah
    final todos = ref.watch(todoListProvider);
    // Derived provider → hanya todo yang belum selesai
    final remaining = ref.watch(filteredTodoProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Riverpod'),
        // Tampilkan jumlah tugas yang belum selesai
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$remaining tugas',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: todos.isEmpty
          ? const Center(child: Text('Belum ada tugas'))
          : ListView.builder(
              itemCount: todos.length,
              // Refactoring: gunakan TodoTile (widget terpisah)
              itemBuilder: (context, index) => TodoTile(
                index: index,
                todo: todos[index],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Dialog untuk menambah todo baru.
  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(todoListProvider.notifier)
                    .add(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}