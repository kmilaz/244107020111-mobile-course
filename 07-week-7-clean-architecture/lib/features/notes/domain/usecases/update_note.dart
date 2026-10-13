import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Menyimpan perubahan lokal pada catatan.
///
/// Aturan domain: setiap perubahan lokal memakai **waktu sekarang** sebagai
/// `updatedAt` (dasar aturan konflik *last-write-wins*) dan **wajib** ditandai
/// `dirty` supaya masuk antrean sinkronisasi. Dua hal itu tidak boleh
/// bergantung pada widget mana yang menyimpan.
class UpdateNote {
  const UpdateNote(this._repository);

  final NoteRepository _repository;

  Future<({bool ok, Failure? failure})> call({
    required Note note,
    required String title,
    required String body,
  }) {
    final id = note.id;
    if (id == null) {
      return Future.value((
        ok: false,
        failure: const LocalFailure('Catatan belum tersimpan di database'),
      ));
    }

    return _repository.updateNote(
      Note(
        id: id,
        title: title.trim(),
        body: body,
        updatedAt: DateTime.now(),
        dirty: true,
      ),
    );
  }
}
