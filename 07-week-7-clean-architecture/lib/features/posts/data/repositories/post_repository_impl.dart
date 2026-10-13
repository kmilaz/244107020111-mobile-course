import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../models/post_model.dart';

/// Sumber remote untuk posts. Tugasnya hanya dua: memanggil API, dan
/// **mengubah `DioException` menjadi `Failure`** yang pesannya layak dibaca
/// pengguna.
class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<({List<Post> posts, Failure? failure})> fetchPosts() async {
    try {
      final response = await _dio.get<List<dynamic>>('/posts');
      final data = response.data ?? const <dynamic>[];
      final posts = data
          .whereType<Map<String, dynamic>>()
          .map((json) => PostModel.fromJson(json).toEntity())
          .toList();
      return (posts: posts, failure: null);
    } on DioException catch (e) {
      return (posts: const <Post>[], failure: NetworkFailure(_pesan(e)));
    } catch (e) {
      return (
        posts: const <Post>[],
        failure: NetworkFailure('Gagal memuat posts: $e'),
      );
    }
  }

  /// Mengubah jenis kegagalan jaringan menjadi pesan untuk pengguna.
  static String _pesan(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Koneksi terlalu lama. Periksa jaringanmu.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return 'Server menolak permintaan ($code).';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.unknown:
        return 'Gagal menghubungi server.';
    }
  }
}
