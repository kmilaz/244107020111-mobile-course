import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Seluruh token hanya keluar-masuk lewat kelas ini.
///
/// Refresh token **tidak pernah** disimpan di SharedPreferences: SharedPreferences
/// tersimpan sebagai file biasa di sandbox aplikasi, sehingga mudah terbaca pada
/// perangkat yang di-root atau lewat backup. Secure storage memakai Keystore/
/// Keychain yang terikat ke perangkat.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> readAccess() => _storage.read(key: _accessKey);

  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> clear() => _storage.deleteAll();

  /// Potongan token untuk ditampilkan atau dicatat (mis. ke log).
  ///
  /// Token utuh **tidak boleh** muncul di log, screenshot, maupun pesan error.
  /// Fungsi ini yang membuat bukti screenshot tetap aman.
  static String mask(String? token) {
    if (token == null || token.isEmpty) return '(kosong)';
    if (token.length <= 8) return '••••••••';
    return '${token.substring(0, 4)}••••••••${token.substring(token.length - 4)}';
  }
}
