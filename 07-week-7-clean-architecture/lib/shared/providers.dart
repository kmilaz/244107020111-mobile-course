import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flag demo lintas fitur: memaksa aplikasi memakai jalur offline supaya
/// demonstrasi tidak bergantung pada kondisi Wi-Fi.
///
/// Diletakkan di `lib/shared/` (bukan di dalam salah satu fitur) karena ia
/// memengaruhi dua fitur sekaligus: refresh posts **dan** antrean sync catatan.
/// Berkas ini hanya berisi state presentasi, bukan logika bisnis.
final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false; // nilai awal sudah diketahui → Notifier (sinkron)

  void set(bool value) => state = value;
}
