import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/note.dart';
import 'models/post.dart';
import 'prefs.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';
import 'sync.dart';

// ---------------------------------------------------------------- repository
// Satu-satunya tempat yang menyentuh platform: sqflite, SharedPreferences, Dio.

final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(),
);

/// Cache `cached_posts` — dipisah dari `PostRepository` (Refactoring Challenge
/// #2) supaya repository tetap menjadi sumber remote murni.
final postsCacheProvider = Provider<PostsCache>((ref) => PostsCache());

// ----------------------------------------------------------------- preferensi

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

// --------------------------------------------------------------- flag offline

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false; // nilai awal sudah diketahui → Notifier (sinkron)

  void set(bool value) => state = value;
}

// ------------------------------------------------------------ catatan (TULIS)

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

  Future<void> updateNote(Note note) async {
    await _repo.updateNote(note);
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

/// Jumlah catatan yang belum tersinkron (badge antrean sync).
final dirtyCountProvider = FutureProvider<int>((ref) {
  ref.watch(notesProvider); // hitung ulang setiap daftar berubah
  return ref.watch(noteRepositoryProvider).countDirty();
});

/// Satu catatan berdasarkan id — dipakai halaman detail.
///
/// Membaca dari repository, bukan dari state daftar, supaya deep link
/// `/note/:id` tetap bekerja tanpa halaman daftar pernah dibuka.
final noteByIdProvider = FutureProvider.family<Note?, int>(
  (ref, id) => ref.watch(noteRepositoryProvider).getNote(id),
);

// -------------------------------------------------------------- posts (BACA)

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

/// Cache-first read: tampilkan `cached_posts` seketika, lalu refresh dari
/// jaringan di background dan timpa cache.
class PostsNotifier extends Notifier<PostsState> {
  @override
  PostsState build() {
    // listen, BUKAN watch: mengubah toggle harus menjalankan ulang load
    // TANPA membuang posts yang sedang tampil di layar.
    ref.listen(forceOfflineProvider, (_, _) => load());
    Future.microtask(load);
    return const PostsState(isLoading: true);
  }

  Future<void> load() async {
    final repo = ref.read(postRepositoryProvider);
    final cache = ref.read(postsCacheProvider);
    final forceOffline = ref.read(forceOfflineProvider);

    // 1. CACHE DULU → layar terisi seketika, tanpa menunggu jaringan.
    final cached = await cache.read();
    state = PostsState(
      posts: cached,
      source: PostsSource.cache,
      lastCachedAt: await cache.lastCachedAt(),
      isLoading: !forceOffline,
    );

    if (forceOffline) return; // demo offline deterministik

    // 2. Refresh dari jaringan di belakang, lalu timpa cache.
    try {
      final fresh = await repo.fetchPosts();
      await cache.replaceAll(fresh);
      state = PostsState(
        posts: fresh,
        source: PostsSource.network,
        lastCachedAt: DateTime.now(),
      );
    } catch (error) {
      // Gagal jaringan bukan alasan menghapus data yang sudah tampil.
      state = state.copyWith(isLoading: false, error: '$error');
    }
  }
}
