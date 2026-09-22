import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// TodoProvider — state management untuk daftar tugas.
//
// Concept:
// - Notifier<List<Todo>> → state yang bisa berubah melalui method
// - NotifierProvider → menjembatani Notifier dengan UI
// - Immutability → setiap perubahan membuat list baru, bukan mutasi langsung
// ============================================================

/// Model Todo — immutable, menggunakan copyWith() untuk perubahan.
class Todo {
  Todo(this.title, {this.done = false});
  final String title;
  final bool done;

  /// copyWith → membuat salinan dengan nilai baru.
  /// Parameter optional, jika null gunakan nilai lama.
  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done);
}

/// TodoListNotifier — mengelola state List Todo.
///
/// State tidak pernah diubah langsung (state.add() = salah!).
/// Selalu buat list baru: [...state, newItem].
class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  /// Tambah todo baru → buat list baru dengan item tambahan.
  void add(String title) => state = [...state, Todo(title)];

  /// Toggle status done → buat list baru dengan item yang diubah.
  void toggle(int index) {
    final todos = [...state];
    todos[index] = todos[index].copyWith(done: !todos[index].done);
    state = todos;
  }

  /// Hapus todo → buat list baru tanpa item tersebut.
  void remove(int index) => state = [...state]..removeAt(index);
}

/// Deklarasi provider — digunakan oleh UI dan provider lain.
final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

// ============================================================
// FilteredTodoProvider — Provider turunan (derived provider).
//
// Concept:
// - Provider yang membaca provider lain (todoListProvider)
// - Menggunakan `ref.watch` agar otomatis rebuild saat data berubah
// - Memisahkan logika filter dari UI (separation of concerns)
// ============================================================

/// Provider untuk menampilkan hanya todo yang belum selesai.
/// Berguna untuk halaman statistik atau filter aktivitas.
final filteredTodoProvider = Provider<List<Todo>>((ref) {
  // ref.watch → berlangganan, rebuild saat todoListProvider berubah
  final todos = ref.watch(todoListProvider);
  // Filter: hanya todo yang done = false
  return todos.where((todo) => !todo.done).toList();
});
