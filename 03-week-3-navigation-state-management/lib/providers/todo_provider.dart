import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  Todo(this.title, {this.done = false});
  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done);
}

class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  void add(String title) => state = [...state, Todo(title)];

  void toggle(int index) {
    final todos = [...state];
    todos[index] = todos[index].copyWith(done: !todos[index].done);
    state = todos;
  }

  void remove(int index) => state = [...state]..removeAt(index);
}

class TodoStatsNotifier extends AsyncNotifier<Map<String, int>> {
  @override
Future<Map<String, int>> build() async {
  await Future.delayed(const Duration(seconds: 2));
  throw Exception('Gagal terhubung ke server'); 

  final todos = ref.watch(todoListProvider);
  final total = todos.length;
  final done = todos.where((t) => t.done).length;

  if (DateTime.now().millisecond % 10 < 3) {
    throw Exception('Gagal terhubung ke server');
  }

  return {'total': total, 'done': done, 'remaining': total - done};
}

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final todoStatsProvider =
    AsyncNotifierProvider<TodoStatsNotifier, Map<String, int>>(TodoStatsNotifier.new);

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);
