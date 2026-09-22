import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

// ============================================================
// TodoTile — widget terpisah untuk satu baris todo.
//
// Refactoring: memisahkan tile dari TodoPage agar:
// 1. build() di TodoPage lebih pendek dan mudah dibaca
// 2. Tile bisa diuji secara terpisah
// 3. Bisa direuse di tempat lain jika diperlukan
// ============================================================

/// ConsumerWidget karena butuh akses `ref` untuk toggle dan remove.
class TodoTile extends ConsumerWidget {
  final int index;
  final Todo todo;

  const TodoTile({
    super.key,
    required this.index,
    required this.todo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Checkbox(
        value: todo.done,
        // ref.read → sekali baca di callback
        onChanged: (_) =>
            ref.read(todoListProvider.notifier).toggle(index),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.done ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () =>
            ref.read(todoListProvider.notifier).remove(index),
      ),
    );
  }
}
