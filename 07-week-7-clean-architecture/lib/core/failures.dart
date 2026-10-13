/// Kegagalan yang bisa ditampilkan ke pengguna.
///
/// Murni Dart — tanpa import Flutter, Dio, atau sqflite — sehingga domain tetap
/// bisa diuji di mana saja, dan UI hanya menerima pesan yang sudah ramah.
sealed class Failure {
  const Failure(this.message);
  final String message;

  /// Supaya `'$failure'` langsung menghasilkan pesan yang layak dibaca
  /// pengguna — UI tidak perlu membongkar tipe exception apa pun.
  @override
  String toString() => message;
}

/// Gagal di penyimpanan lokal (database/preferensi).
class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

/// Gagal saat menghubungi jaringan.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
