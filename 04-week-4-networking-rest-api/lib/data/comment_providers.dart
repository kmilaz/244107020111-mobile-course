import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';
// Import dioProvider dari providers.dart yang sudah ada
import 'providers.dart';

// =============================================================================
// PROVIDERS — Dependency Injection untuk layer data
// =============================================================================

/// Provider untuk instance CommentRepository.
/// Menggunakan dioProvider dari providers.dart supaya seluruh app berbagi
/// satu Dio client dengan konfigurasi yang sama (baseUrl, timeout, logging).
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

/// Provider untuk state komentar per postingan.
///
/// Menggunakan AsyncNotifierProvider.autoDispose.family agar:
/// 1. State otomatis berupa AsyncValue (loading / error / data)
/// 2. autoDispose: state dibuang dari memory saat tidak di-watch
/// 3. family: menerima parameter postId (int)
///
/// Cara pakai di widget:
///   ref.watch(commentProvider(postId))
/// otomatis fetch komentar untuk postId tertentu.
final commentProvider = AsyncNotifierProvider.autoDispose
    .family<CommentNotifier, List<Comment>, int>(
  CommentNotifier.new,
  // Nonaktifkan retry otomatis agar error langsung final dan mudah diuji.
  retry: (retryCount, error) => null,
);

// =============================================================================
// NOTIFIER — Logic untuk mengambil data komentar
// =============================================================================

/// AsyncNotifier yang mengelola state komentar untuk satu postingan.
///
/// Di Riverpod 3.x, family argument di-pass lewat CONSTRUCTOR, bukan build().
/// Saat widget memanggil ref.watch(commentProvider(5)):
/// Riverpod membuat CommentNotifier(postId: 5)
/// build() dipanggil tanpa argumen, tapi postId sudah tersimpan.
class CommentNotifier extends AsyncNotifier<List<Comment>> {
  /// Constructor menerima postId dari family.
  CommentNotifier(this.postId);
  final int postId;

  /// build() dipanggil pertama kali saat provider di-watch.
  /// Tidak ada argumen — postId diakses dari field constructor.
  @override
  Future<List<Comment>> build() async {
    final repository = ref.watch(commentRepositoryProvider);
    // Exception dari repository otomatis menjadi AsyncError.
    // Tidak perlu try/catch — Riverpod menangani semuanya.
    return repository.fetchComments(postId);
  }
}

// =============================================================================
// ERROR HANDLING — Pesan error ramah pengguna
// =============================================================================

/// Mengubah exception teknis (DioException) menjadi pesan yang mudah
/// dimengerti oleh pengguna aplikasi.
///
/// Pola ini penting: user tidak perlu tahu "DioExceptionType.connectionError".
/// Mereka perlu tahu "Periksa internet Anda".
///
/// DioExceptionType yang ditangani:
/// - connectionTimeout / sendTimeout / receiveTimeout → masalah jaringan lambat
/// - connectionError → tidak bisa terhubung ke server
/// - badResponse (404, 401, 403, 500) → error dari server
/// - lainnya → error tak terduga
String friendlyCommentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      // Timeout: koneksi lambat atau server tidak merespons
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';

      // Tidak bisa terhubung: server down atau tidak ada internet
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';

      // Server merespons dengan status error
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Data tidak ditemukan (404).';
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Periksa kredensial Anda.';
        }
        return 'Server bermasalah ($code). Coba lagi nanti.';

      // Error lain: cancel, bad certificate, dll
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  // Bukan DioException → error tak terduga dari kode kita sendiri
  return 'Terjadi kesalahan tak terduga: $error';
}
