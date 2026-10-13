import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_week_6/data/api_errors.dart';
import 'package:mobile_week_6/data/token_store.dart';
import 'package:mobile_week_6/routes.dart';

/// Token store palsu — tidak menyentuh secure storage (plugin native).
class FakeTokenStore {
  String? access;
  String? refresh;

  bool get hasSession => access != null && access!.isNotEmpty;

  void clear() {
    access = null;
    refresh = null;
  }
}

DioException _badResponse(int statusCode) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: statusCode,
  ),
);

void main() {
  group('routeFromMessage (Refactoring Challenge #2)', () {
    test('route kosong → beranda', () {
      expect(routeFromMessage({}), AppRoutes.home);
    });

    test('tanpa slash di depan → ditambahkan', () {
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    });

    test('sudah ada slash → apa adanya', () {
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('spasi di sekitar route di-trim', () {
      expect(routeFromMessage({'route': '  /pengumuman/7 '}), '/pengumuman/7');
    });

    test('URL dengan skema eksternal ditolak → beranda', () {
      expect(
        routeFromMessage({'route': 'https://jahat.test/x'}),
        AppRoutes.home,
      );
    });

    test('data payload membawa id pengumuman', () {
      const data = {'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(routeFromMessage(data), '/pengumuman/3');
    });
  });

  group('TokenStore.mask (keamanan token)', () {
    test('hanya menyisakan 4 karakter awal dan akhir', () {
      final masked = TokenStore.mask(
        'mock-access-for-mahasiswa@polinema.ac.id',
      );
      expect(masked, startsWith('mock'));
      expect(masked, endsWith('.id'));
      expect(masked, contains('••'));
      expect(
        masked,
        isNot(contains('mahasiswa@polinema.ac.id')),
        reason: 'token utuh tidak boleh ikut tampil',
      );
    });

    test('token kosong atau null tetap aman', () {
      expect(TokenStore.mask(null), '(kosong)');
      expect(TokenStore.mask(''), '(kosong)');
    });

    test('token pendek tidak bocor utuh', () {
      expect(TokenStore.mask('abc123'), '••••••••');
    });
  });

  group('logika sesi dan refresh', () {
    test('ada access token berarti sudah login', () {
      final store = FakeTokenStore()..access = 'mock-access';
      expect(store.hasSession, isTrue);

      store.clear();
      expect(store.hasSession, isFalse);
    });

    test('refresh kosong → sesi dibersihkan, paksa login ulang', () {
      final store = FakeTokenStore()..refresh = '';
      expect((store.refresh ?? '').isEmpty, isTrue);

      store.clear();
      expect(store.hasSession, isFalse);
    });
  });

  group('friendlyApiError (Refactoring Challenge #3)', () {
    test('timeout → pesan ramah', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(friendlyApiError(error), contains('lama'));
    });

    test('tidak ada koneksi → pesan ramah', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );
      expect(friendlyApiError(error), contains('internet'));
    });

    test('401 → diminta masuk lagi', () {
      expect(friendlyApiError(_badResponse(401)), contains('masuk lagi'));
    });

    test('500 → server bermasalah', () {
      expect(friendlyApiError(_badResponse(500)), contains('Server'));
    });

    test('error non-Dio → pesan umum', () {
      expect(friendlyApiError(Exception('apa saja')), contains('tak terduga'));
    });
  });
}
