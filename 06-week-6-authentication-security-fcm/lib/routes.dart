/// Semua path rute dipusatkan di sini (Refactoring Challenge #1), supaya
/// GoRouter dan deep link dari FCM memakai konstanta yang sama. Kalau salah
/// satu berubah, yang lain tidak bisa ketinggalan.
class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String home = '/';
  static const String announcement = '/pengumuman/:id';

  /// Path konkret untuk satu pengumuman.
  static String announcementFor(String id) => '/pengumuman/$id';
}

/// Mengubah data payload FCM menjadi path rute (Refactoring Challenge #2).
///
/// Fungsi murni — tidak menyentuh Firebase sama sekali, sehingga bisa diuji
/// tanpa perangkat maupun project Firebase.
///
/// Aturan:
/// - tidak ada `route` → beranda;
/// - `pengumuman/3` (tanpa slash) → `/pengumuman/3`;
/// - URL dengan skema (`https://…`) DITOLAK → beranda, supaya payload tidak
///   bisa mengarahkan aplikasi ke luar.
String routeFromMessage(Map<String, dynamic> data) {
  final raw = (data['route'] as String?)?.trim() ?? '';
  if (raw.isEmpty) return AppRoutes.home;
  if (raw.contains('://')) return AppRoutes.home;
  return raw.startsWith('/') ? raw : '/$raw';
}
