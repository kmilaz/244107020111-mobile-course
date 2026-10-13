import 'package:dio/dio.dart';

/// Mengubah `DioException` menjadi pesan yang bisa dibaca pengguna
/// (Refactoring Challenge #3), sehingga layer UI hanya menerima pesan dan tidak
/// pernah menyentuh exception jaringan mentah.
String friendlyApiError(Object error) {
  if (error is! DioException) return 'Terjadi kesalahan tak terduga.';

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Koneksi terlalu lama. Periksa jaringanmu.';
    case DioExceptionType.connectionError:
      return 'Tidak ada koneksi internet.';
    case DioExceptionType.badCertificate:
      return 'Sertifikat server tidak valid.';
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode;
      if (code == 401) return 'Sesi sudah berakhir. Silakan masuk lagi.';
      if (code == 403) return 'Kamu tidak punya akses ke data ini.';
      if (code == 404) return 'Data tidak ditemukan.';
      if (code != null && code >= 500) return 'Server sedang bermasalah.';
      return 'Permintaan ditolak server ($code).';
    case DioExceptionType.unknown:
      return 'Gagal menghubungi server.';
  }
}
