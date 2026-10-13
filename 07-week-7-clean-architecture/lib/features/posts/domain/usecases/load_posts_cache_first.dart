import '../../../../core/failures.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';
import '../repositories/posts_cache.dart';

/// Kebijakan **cache-first** untuk posts — inilah aturan bisnis yang membuat
/// use case ini layak ada:
///
/// 1. baca cache lebih dulu, supaya layar terisi seketika dan tetap terisi saat
///    tidak ada internet;
/// 2. baru ambil dari jaringan, lalu timpa cache untuk kunjungan berikutnya.
///
/// Notifier hanya menerjemahkan hasil tiap fase ke state UI — urutannya tidak
/// ditentukan di presentation.
class LoadPostsCacheFirst {
  const LoadPostsCacheFirst(this._remote, this._cache);

  final PostRepository _remote;
  final PostsCache _cache;

  /// Fase 1 — dari cache.
  Future<({List<Post> posts, DateTime? cachedAt, Failure? failure})>
  fromCache() async {
    final cached = await _cache.read();
    if (cached.failure != null) {
      return (posts: const <Post>[], cachedAt: null, failure: cached.failure);
    }

    final stamp = await _cache.lastCachedAt();
    return (posts: cached.posts, cachedAt: stamp.cachedAt, failure: null);
  }

  /// Fase 2 — dari jaringan, lalu timpa cache.
  Future<({List<Post> posts, Failure? failure})> refresh() async {
    final fresh = await _remote.fetchPosts();
    if (fresh.failure != null) {
      // Gagal jaringan bukan alasan menghapus cache yang sudah tampil.
      return (posts: const <Post>[], failure: fresh.failure);
    }

    await _cache.replaceAll(fresh.posts);
    return (posts: fresh.posts, failure: null);
  }
}
