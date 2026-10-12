import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/note.dart';
import 'models/post.dart';
import 'prefs.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';

final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(),
);

final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final lastOpenedProvider = FutureProvider<String?>(
  (ref) => ref.watch(prefsRepositoryProvider).getLastOpened(),
);

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  NoteRepository get _repo => ref.read(noteRepositoryProvider);

  @override
  Future<List<Note>> build() => _repo.fetchNotes();

  Future<void> add({required String title, String body = ''}) async {
    await _repo.addNote(title: title, body: body);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await _repo.deleteNote(id);
    ref.invalidateSelf();
  }

  /// Kirim antrean, lalu muat ulang daftar.
  Future<int> sync() async {
    final synced = await syncNotes(_repo);
    ref.invalidateSelf();
    return synced;
  }
}

final dirtyCountProvider = FutureProvider<int>((ref) {
  ref.watch(notesProvider);
  return ref.watch(noteRepositoryProvider).countDirty();
});

enum PostsSource { none, cache, network }

class PostsState {
  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.source = PostsSource.none,
    this.lastCachedAt,
    this.error,
  });

  final List<Post> posts;
  final bool isLoading;
  final PostsSource source;
  final DateTime? lastCachedAt;
  final String? error;

  PostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    PostsSource? source,
    DateTime? lastCachedAt,
    String? error,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      source: source ?? this.source,
      lastCachedAt: lastCachedAt ?? this.lastCachedAt,
      error: error ?? this.error,
    );
  }
}

final postsProvider = NotifierProvider<PostsNotifier, PostsState>(
  PostsNotifier.new,
);

class PostsNotifier extends Notifier<PostsState> {
  @override
  PostsState build() {
    ref.listen(forceOfflineProvider, (_, _) => load());
    Future.microtask(load);
    return const PostsState(isLoading: true);
  }

  Future<void> load() async {
    final repo = ref.read(postRepositoryProvider);
    final forceOffline = ref.read(forceOfflineProvider);

    final cached = await repo.readCached();
    state = PostsState(
      posts: cached,
      source: PostsSource.cache,
      lastCachedAt: await repo.lastCachedAt(),
      isLoading: !forceOffline,
    );

    if (forceOffline) return;

    try {
      final fresh = await repo.fetchPosts();
      await repo.replaceAll(fresh);
      state = PostsState(
        posts: fresh,
        source: PostsSource.network,
        lastCachedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: '$error');
    }
  }
}
