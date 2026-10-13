import '../../../../core/failures.dart';
import '../entities/note.dart';

/// Kontrak yang dibutuhkan domain. Implementasinya (SQLite) ada di layer data.
///
/// Memakai *record* `({nilai, failure})` supaya sukses dan gagal eksplisit —
/// exception tidak bocor ke presentation.
///
/// Perhatikan: repository ini **hanya menyimpan dan membaca apa adanya**.
/// Seluruh aturan (kapan `dirty` diset, urutan antrean) ada di use case, karena
/// aturan bisnis adalah milik domain, bukan milik SQLite.
abstract class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();

  Future<({Note? note, Failure? failure})> getNote(int id);

  /// Menyimpan entity yang sudah disiapkan use case; id dikembalikan database.
  Future<({Note? note, Failure? failure})> insertNote(Note note);

  Future<({bool ok, Failure? failure})> updateNote(Note note);

  Future<({bool ok, Failure? failure})> deleteNote(int id);

  /// Pintu untuk antrean sinkronisasi.
  Future<({List<Note> notes, Failure? failure})> fetchDirty();

  /// Menandai SATU catatan bersih — dipanggil hanya setelah server menerimanya.
  Future<({bool ok, Failure? failure})> markSynced(int id);
}
