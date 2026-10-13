import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Menambah catatan baru.
///
/// Aturan domainnya ada di sini, bukan di repository: catatan yang baru dibuat
/// **selalu** bertanda `dirty` (belum pernah ada di server), dan judul kosong
/// ditolak sebelum menyentuh database.
class AddNote {
  const AddNote(this._repository);

  final NoteRepository _repository;

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return Future.value((
        note: null,
        failure: const LocalFailure('Judul catatan tidak boleh kosong'),
      ));
    }

    return _repository.insertNote(
      Note(title: trimmed, body: body, updatedAt: DateTime.now(), dirty: true),
    );
  }
}
