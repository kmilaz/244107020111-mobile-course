import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prefs.dart';
import 'local/note.dart';
import 'repositories/note_repository.dart';

final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
);

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);

    state = const AsyncLoading();                        
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final lastOpenedProvider = FutureProvider<String?>(
  (ref) => ref.watch(prefsRepositoryProvider).getLastOpened(),
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  NoteRepository get _repo => ref.read(noteRepositoryProvider);

  // build() = memuat daftar awal dari database
  @override
  Future<List<Note>> build() => _repo.fetchNotes();

  Future<void> add({required String title, String body = ''}) async {
    await _repo.addNote(title: title, body: body);
    ref.invalidateSelf(); // ← muat ulang daftar
  }

  Future<void> remove(int id) async {
    await _repo.deleteNote(id);
    ref.invalidateSelf();
  }
}

/// Jumlah catatan yang belum tersinkron (badge antrean sync).
final dirtyCountProvider = FutureProvider<int>((ref) {
  ref.watch(notesProvider); // hitung ulang setiap daftar berubah
  return ref.watch(noteRepositoryProvider).countDirty();
});