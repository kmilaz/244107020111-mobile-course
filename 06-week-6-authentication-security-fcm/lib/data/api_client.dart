import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

/// Dio dengan **refresh otomatis**: saat menerima 401, coba tukar refresh token
/// SEKALI, lalu ulangi request. Kalau refresh ikut mati → sesi dibersihkan dan
/// pengguna dipaksa login ulang.
///
/// Ganti `baseUrl` dengan alamat API kampus.
Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example-campus-api.test',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) return handler.next(error);

        // Sudah pernah dicoba sekali untuk request ini → jangan ulangi lagi,
        // supaya 401 tidak berubah menjadi lingkaran tak berujung.
        if (error.requestOptions.extra['retried'] == true) {
          await store.clear();
          return handler.next(error);
        }

        final refresh = await store.readRefresh();
        if (refresh == null || refresh.isEmpty) {
          await store.clear();
          return handler.next(error);
        }

        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);

          final retryOptions = error.requestOptions
            ..extra['retried'] = true
            ..headers['Authorization'] = 'Bearer $renewed';
          final response = await dio.fetch(retryOptions);
          return handler.resolve(response);
        } catch (_) {
          // Refresh ikut kedaluwarsa → bersihkan sesi, arahkan ke /login.
          await store.clear();
          return handler.next(error);
        }
      },
    ),
  );

  return dio;
}
