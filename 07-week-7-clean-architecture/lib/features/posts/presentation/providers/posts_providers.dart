import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/db.dart';
import '../../../../shared/providers.dart';
import '../../data/api_client.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../data/repositories/posts_cache_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/repositories/posts_cache.dart';
import '../../domain/usecases/load_posts_cache_first.dart';

// ---------------------------------------------------------------- data layer
// Composition root fitur posts: di sinilah implementasi konkret dipasang.
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepositoryImpl(createPostDio()),
);

final postsCacheProvider = Provider<PostsCache>(
  (ref) => PostsCacheImpl(openNotesDb),
);

// -------------------------------------------------------------- domain layer
final loadPostsCacheFirstProvider = Provider(
  (ref) => LoadPostsCacheFirst(
    ref.watch(postRepositoryProvider),
    ref.watch(postsCacheProvider),
  ),
);

// -------------------------------------------------------- presentation layer
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

/// Cache-first read. Urutannya ditentukan use case; notifier hanya
/// menerjemahkan tiap fase ke state UI.
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
    final useCase = ref.read(loadPostsCacheFirstProvider);
    final forceOffline = ref.read(forceOfflineProvider);

    // Fase 1 — cache dulu: layar terisi seketika, tanpa menunggu jaringan.
    final cached = await useCase.fromCache();
    state = PostsState(
      posts: cached.posts,
      source: PostsSource.cache,
      lastCachedAt: cached.cachedAt,
      isLoading: !forceOffline,
    );

    if (forceOffline) return; // demo offline deterministik

    // Fase 2 — refresh dari jaringan, lalu timpa cache.
    final fresh = await useCase.refresh();
    if (fresh.failure != null) {
      // Pesannya sudah ramah: layer data mengubah DioException menjadi Failure.
      state = state.copyWith(isLoading: false, error: fresh.failure!.message);
      return;
    }

    state = PostsState(
      posts: fresh.posts,
      source: PostsSource.network,
      lastCachedAt: DateTime.now(),
    );
  }
}
