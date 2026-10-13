import 'package:dio/dio.dart';

/// Dio khusus fitur posts. Base URL dan timeout dikonfigurasi di satu tempat.
Dio createPostDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
  return dio;
}
