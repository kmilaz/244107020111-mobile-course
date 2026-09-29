import 'package:dio/dio.dart';
import '../models/comment.dart';

/// Repository untuk mengambil data komentar dari JSONPlaceholder API.
///
/// Mengikuti repository pattern: satu-satunya pintu akses ke sumber data.
/// UI tidak boleh memanggil Dio secara langsung — semua lewat repository ini.
/// Exception dibiarkan naik (tidak di-catch) agar provider bisa mengubahnya
/// menjadi AsyncError secara otomatis.
class CommentRepository {
  /// Dio di-inject melalui constructor agar mudah di-mock saat testing.
  CommentRepository(this._dio);
  final Dio _dio;

  /// Mengambil semua komentar untuk satu postingan tertentu.
  ///
  /// Endpoint: GET /comments?postId={postId}
  /// Dio sudah dikonfigurasi timeout 10 detik di api_client.dart,
  /// jadi jika server tidak merespons dalam 10 detik → DioException.
  ///
  /// Parameter:
  /// - [postId]: ID postingan yang komentarnya ingin diambil.
  ///
  /// Mengembalikan `List<Comment>` yang sudah di-parsing dari JSON.
  Future<List<Comment>> fetchComments(int postId) async {
    // Kirim request GET dengan query parameter postId
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // response.data bisa null jika body kosong → fallback ke list kosong
    final data = response.data ?? [];

    // Filter hanya item yang benar-benar Map (buang null/Type salah),
    // lalu mapping setiap item ke objek Comment menggunakan fromJson.
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
