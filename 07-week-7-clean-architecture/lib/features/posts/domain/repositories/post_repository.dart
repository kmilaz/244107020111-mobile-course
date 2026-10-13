import '../../../../core/failures.dart';
import '../entities/post.dart';

/// Kontrak sumber **jaringan** untuk posts. Implementasi Dio ada di layer data.
///
/// Sukses dan gagal dibuat eksplisit lewat record, supaya `DioException` tidak
/// bocor ke presentation.
abstract class PostRepository {
  Future<({List<Post> posts, Failure? failure})> fetchPosts();
}
