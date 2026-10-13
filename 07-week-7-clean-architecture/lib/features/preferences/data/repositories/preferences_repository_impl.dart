import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/failures.dart';
import '../../domain/repositories/preferences_repository.dart';

/// Implementasi preferensi di SharedPreferences.
///
/// Setiap kegagalan platform diubah menjadi [LocalFailure] dengan pesan yang
/// layak dibaca — UI tidak pernah menerima exception mentah.
class PreferencesRepositoryImpl implements PreferencesRepository {
  static const String _darkModeKey = 'dark_mode';
  static const String _lastOpenedKey = 'last_opened_at';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<({bool value, Failure? failure})> darkMode() async {
    try {
      final prefs = await _prefs;
      return (value: prefs.getBool(_darkModeKey) ?? false, failure: null);
    } catch (e) {
      return (value: false, failure: LocalFailure('Gagal membaca tema: $e'));
    }
  }

  @override
  Future<({bool ok, Failure? failure})> setDarkMode(bool value) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(_darkModeKey, value);
      return (ok: true, failure: null);
    } catch (e) {
      return (ok: false, failure: LocalFailure('Gagal menyimpan tema: $e'));
    }
  }

  @override
  Future<({bool ok, Failure? failure})> markOpenedNow() async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
      return (ok: true, failure: null);
    } catch (e) {
      return (
        ok: false,
        failure: LocalFailure('Gagal mencatat waktu buka: $e'),
      );
    }
  }

  @override
  Future<({String? value, Failure? failure})> lastOpened() async {
    try {
      final prefs = await _prefs;
      return (value: prefs.getString(_lastOpenedKey), failure: null);
    } catch (e) {
      return (
        value: null,
        failure: LocalFailure('Gagal membaca waktu buka: $e'),
      );
    }
  }
}
