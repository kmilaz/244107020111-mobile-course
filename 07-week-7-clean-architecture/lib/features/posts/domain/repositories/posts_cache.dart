import '../../../../core/failures.dart';
import '../entities/post.dart';

/// Kontrak penyimpanan **cache lokal** untuk posts (tabel `cached_posts`).
///
/// Dipisah dari [PostRepository] supaya sumber jaringan dan sumber lokal bisa
/// diganti terpisah saat test.
abstract class PostsCache {
  Future<({List<Post> posts, Failure? failure})> read();

  Future<({DateTime? cachedAt, Failure? failure})> lastCachedAt();

  /// Menimpa seluruh cache — dipanggil setelah refresh berhasil.
  Future<({bool ok, Failure? failure})> replaceAll(List<Post> posts);
}
