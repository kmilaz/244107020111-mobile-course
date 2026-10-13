import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'prefs.dart';
import 'repositories/post_repository.dart';
import 'sync.dart';

// CATATAN: berkas ini tinggal sebagian. Provider fitur `notes` sudah pindah ke
// `features/notes/presentation/providers/notes_providers.dart`. Isi yang tersisa
// (posts + preferensi) akan dipindahkan ke folder fiturnya masing-masing pada
// Refactoring Challenge, lalu berkas ini dihapus.

// ----------------------------------------------------------------- preferensi
final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
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

// --------------------------------------------------------------- flag offline
final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false; // nilai awal sudah diketahui → Notifier (sinkron)

  void set(bool value) => state = value;
}

// -------------------------------------------------------------- posts (BACA)
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(),
);

/// Cache `cached_posts` — dipisah dari `PostRepository` supaya repository tetap
/// menjadi sumber remote murni.
final postsCacheProvider = Provider<PostsCache>((ref) => PostsCache());

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
