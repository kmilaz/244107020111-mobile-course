import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_provider.dart';

// ============================================================
// StatsProvider — AsyncNotifier yang mensimulasikan pengambilan
// data statistik dari "server" dengan delay 2 detik.
// Kadang gagal 30% untuk mendemonstrasikan penanganan error.
// ============================================================

/// Model sederhana untuk data statistik.
/// Berisi total, selesai, dan sisa tugas.
class TodoStats {
  final int total;
  final int done;
  final int remaining;

  const TodoStats({
    required this.total,
    required this.done,
    required this.remaining,
  });
}

/// AsyncNotifier — state yang bisa berubah melalui method,
/// dengan awal berupa Future (data asinkron).
///
/// - `build()` dijalankan pertama kali → return Future (delay + fetch)
/// - UI menggunakan `AsyncValue.when()` untuk handle loading/error/data
/// - `ref.watch(todoListProvider)` di dalam build() membuat provider ini
///   otomatis rebuild saat todoListProvider berubah
class StatsNotifier extends AsyncNotifier<TodoStats> {
  @override
  Future<TodoStats> build() async {
    // Simulasi delay pengambilan data dari API/database (2 detik)
    await Future.delayed(const Duration(seconds: 2));

    // `ref.watch` — berlangganan ke todoListProvider.
    // Jika todo berubah, StatsNotifier otomatis rebuild.
    final todos = ref.watch(todoListProvider);
    final total = todos.length;
    final done = todos.where((t) => t.done).length;

    // Simulasi kegagalan server ~30% (untuk testing AsyncValue.error)
    // Hapus baris ini saat demo agar selalu berhasil.
    if (DateTime.now().millisecond % 10 < 3) {
      throw Exception('Gagal terhubung ke server');
    }

    // Return data statistik → akan jadi AsyncValue.data
    return TodoStats(
      total: total,
      done: done,
      remaining: total - done,
    );
  }

  /// Method refresh — dipanggil oleh UI (tombol "Coba lagi" atau pull-to-refresh).
  ///
  /// 1. Set state ke AsyncLoading() → UI tampilkan spinner
  /// 2. Panggil build() ulang dengan AsyncValue.guard() → auto-catch exception
  ///    menjadi AsyncError, tidak perlu try/catch manual.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

/// Deklarasi provider — digunakan oleh UI dan test.
///
/// `AsyncNotifierProvider` menjembatani AsyncNotifier dengan UI.
/// Type: `AsyncNotifierProvider` dengan generic type StatsNotifier dan TodoStats
///   - StatsNotifier = class notifier-nya
///   - TodoStats = tipe state yang dihasilkan
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, TodoStats>(StatsNotifier.new);
