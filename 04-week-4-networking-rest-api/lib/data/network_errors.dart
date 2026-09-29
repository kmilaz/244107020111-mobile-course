/// Fungsi-fungsi untuk menangani error jaringan dan mengubahnya
/// menjadi pesan yang mudah dimengerti oleh pengguna.
///
/// Dipindahkan dari providers.dart agar bisa dipakai ulang oleh:
/// - PostListPage (halaman daftar post tanpa pagination)
/// - PagedPostPage (halaman daftar post dengan pagination)
/// - Halaman lain yang membutuhkan pesan error jaringan
library;

import 'package:dio/dio.dart';

/// Mengubah DioException menjadi pesan error ramah pengguna.
///
/// Setiap jenis DioExceptionType dipetakan ke pesan yang sesuai:
/// - timeout → masalah koneksi lambat
/// - connectionError → tidak ada internet / server down
/// - badResponse 404 → data tidak ditemukan
/// - badResponse 401/403 → akses ditolak
/// - badResponse lainnya → server bermasalah
/// - error lain → pesan umum
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Data tidak ditemukan (404).';
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Periksa kredensial Anda.';
        }
        return 'Server bermasalah ($code). Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}
