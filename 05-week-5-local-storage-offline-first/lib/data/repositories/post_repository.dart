import 'package:dio/dio.dart';

import '../api_client.dart';
import '../models/post.dart';

/// Sumber remote untuk `posts`.
///
/// Persistensi cache dan strategi cache-first tinggal di `lib/data/sync.dart`,
/// sehingga class ini tetap menjadi sumber remote murni.
class PostRepository {
  PostRepository({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List<dynamic>>('/posts');
    final data = response.data ?? const <dynamic>[];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }
}
