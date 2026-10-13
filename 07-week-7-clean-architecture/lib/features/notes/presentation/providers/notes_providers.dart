import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/db.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/sync_notes.dart';
import '../../domain/usecases/update_note.dart';

// ---------------------------------------------------------------- data layer
// Satu-satunya tempat implementasi konkret dipasang. Di test, provider ini
// di-override dengan repository palsu — SQLite tidak pernah tersentuh.
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(openNotesDb),
);

// -------------------------------------------------------------- domain layer
// Use case menerima abstraksi, bukan implementasi.
final addNoteProvider = Provider(
  (ref) => AddNote(ref.watch(noteRepositoryProvider)),
);

final updateNoteProvider = Provider(
  (ref) => UpdateNote(ref.watch(noteRepositoryProvider)),
);

final syncNotesProvider = Provider(
  (ref) => SyncNotes(ref.watch(noteRepositoryProvider)),
);

// -------------------------------------------------------- presentation layer
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  NoteRepository get _repo => ref.read(noteRepositoryProvider);

  @override
  Future<List<Note>> build() async {
    final result = await _repo.fetchNotes();
    if (result.failure != null) throw result.failure!;
    return result.notes;
  }

  Future<void> add({required String title, String body = ''}) async {
    final result = await ref
        .read(addNoteProvider)
        .call(title: title, body: body);
    if (result.failure != null) throw result.failure!;
    ref.invalidateSelf();
  }

  Future<void> updateNote({
    required Note note,
    required String title,
    required String body,
  }) async {
    final result = await ref
        .read(updateNoteProvider)
        .call(note: note, title: title, body: body);
    if (result.failure != null) throw result.failure!;
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    final result = await _repo.deleteNote(id);
    if (result.failure != null) throw result.failure!;
    ref.invalidateSelf();
  }

  /// Kirim antrean lewat use case, lalu muat ulang daftar.
  Future<int> sync() async {
    final result = await ref.read(syncNotesProvider).call();
    if (result.failure != null) throw result.failure!;
    ref.invalidateSelf();
    return result.synced;
  }
}

/// Jumlah catatan belum tersinkron.
///
/// Dihitung dari daftar yang sama (`notesProvider`), bukan query kedua ke
/// database — supaya chip ringkasan dan badge per baris tidak pernah bercerita
/// berbeda.
final dirtyCountProvider = Provider<int>((ref) {
  final notes = ref.watch(notesProvider).value ?? const <Note>[];
  return notes.where((note) => note.dirty).length;
});

/// Satu catatan berdasarkan id.
///
/// Halaman detail membacanya dari repository, **bukan** dari state halaman
/// daftar — supaya deep link `/note/:id` tetap bekerja sendiri.
final noteByIdProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final result = await ref.watch(noteRepositoryProvider).getNote(id);
  if (result.failure != null) throw result.failure!;
  return result.note;
});
