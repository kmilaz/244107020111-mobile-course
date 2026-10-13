import '../../../../core/failures.dart';

/// Kontrak penyimpanan preferensi (tema + waktu terakhir dibuka).
///
/// Sama seperti repository lain: sukses dan gagal dibuat eksplisit lewat
/// record, supaya exception platform tidak bocor ke presentation.
abstract class PreferencesRepository {
  Future<({bool value, Failure? failure})> darkMode();

  Future<({bool ok, Failure? failure})> setDarkMode(bool value);

  Future<({bool ok, Failure? failure})> markOpenedNow();

  Future<({String? value, Failure? failure})> lastOpened();
}
