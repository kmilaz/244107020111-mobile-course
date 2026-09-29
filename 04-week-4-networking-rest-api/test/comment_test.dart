library;

/// Unit test untuk model Comment dan error handling.
///
/// Menjalankan: flutter test test/comment_test.dart
///
/// Test ini memastikan:
/// 1. fromJson aman terhadap field yang hilang (tidak crash)
/// 2. fromJson menghasilkan data yang benar saat semua field ada
/// 3. friendlyCommentErrorMessage menghasilkan pesan yang tepat
///    untuk setiap jenis DioException
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mobile_week_4/data/models/comment.dart';
import 'package:mobile_week_4/data/comment_providers.dart';

void main() {
  // ===========================================================================
  // TEST 1: fromJson aman terhadap field yang hilang
  // ===========================================================================
  // Simulasi: server mengembalikan JSON dengan HANYA field "id".
  // Field lain (postId, name, email, body) tidak ada / null.
  // Yang diharapkan: tidak crash, field kosong mendapat default value.
  test('fromJson aman terhadap field yang hilang', () {
    // JSON dengan field tidak lengkap — hanya ada "id"
    final json = <String, dynamic>{
      'id': 7,
    };

    final comment = Comment.fromJson(json);

    // id berhasil di-parse dari json
    expect(comment.id, 7);
    // Field yang hilang mendapat default value (0 untuk int, '' untuk String)
    expect(comment.postId, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  // ===========================================================================
  // TEST 2: fromJson dengan semua field lengkap (happy path)
  // ===========================================================================
  // Simulasi: server mengembalikan JSON lengkap sesuai dokumentasi API.
  test('fromJson dengan semua field lengkap', () {
    final json = <String, dynamic>{
      'postId': 1,
      'id': 101,
      'name': 'Komentar Pertama',
      'email': 'user@example.com',
      'body': 'Ini isi komentar yang lengkap.',
    };

    final comment = Comment.fromJson(json);

    expect(comment.postId, 1);
    expect(comment.id, 101);
    expect(comment.name, 'Komentar Pertama');
    expect(comment.email, 'user@example.com');
    expect(comment.body, 'Ini isi komentar yang lengkap.');
  });

  // ===========================================================================
  // TEST 3: fromJson dengan tipe data salah (int dikirim sebagai string)
  // ===========================================================================
  // Simulasi: API tidak konsisten — postId dikirim sebagai string "2"
  // bukan integer 2. Cast defensif harus handle ini.
  test('fromJson dengan tipe data bercampur', () {
    final json = <String, dynamic>{
      'postId': '2', // string, bukan int
      'id': 50,
      'name': null, // explicit null
      'email': 'test@mail.com',
      'body': null, // explicit null
    };

    final comment = Comment.fromJson(json);

    // postId: "2" as num? → 2 (Dart otomatis parse string number ke num)
    expect(comment.postId, 2);
    expect(comment.id, 50);
    // name: null as String? → '' (default)
    expect(comment.name, '');
    expect(comment.email, 'test@mail.com');
    // body: null as String? → '' (default)
    expect(comment.body, '');
  });

  // ===========================================================================
  // TEST 4: friendlyCommentErrorMessage untuk setiap jenis error
  // ===========================================================================
  // Memastikan setiap DioExceptionType dipetakan ke pesan yang benar.
  group('friendlyCommentErrorMessage', () {
    test('connectionTimeout → pesan timeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.connectionTimeout,
      );
      final msg = friendlyCommentErrorMessage(error);
      expect(msg, contains('timeout'));
    });

    test('connectionError → pesan tidak terhubung', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.connectionError,
      );
      final msg = friendlyCommentErrorMessage(error);
      expect(msg, contains('terhubung'));
    });

    test('badResponse 404 → data tidak ditemukan', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/comments'),
        ),
      );
      final msg = friendlyCommentErrorMessage(error);
      expect(msg, contains('404'));
    });

    test('badResponse 500 → server bermasalah', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/comments'),
        ),
      );
      final msg = friendlyCommentErrorMessage(error);
      expect(msg, contains('500'));
    });

    test('error biasa (bukan DioException) → pesan tak terduga', () {
      final msg = friendlyCommentErrorMessage(
        StateError('something weird'),
      );
      expect(msg, contains('tak terduga'));
    });
  });
}
