import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_week_7/core/failures.dart';
import 'package:mobile_week_7/features/notes/data/models/note_model.dart';
import 'package:mobile_week_7/features/notes/domain/entities/note.dart';
import 'package:mobile_week_7/features/notes/domain/repositories/note_repository.dart';
import 'package:mobile_week_7/features/notes/domain/usecases/sync_notes.dart';
import 'package:mobile_week_7/features/notes/presentation/providers/notes_providers.dart';

/// Repository palsu: mengimplementasikan **kontrak domain**, tanpa SQLite.
///
/// Tidak ada `openDb` dan tidak ada plugin — seluruh domain bisa diuji di VM
/// biasa tanpa emulator.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({List<Note> items = const [], this.throwError = false})
    : _items = [...items];

  final List<Note> _items;
  final bool throwError;

  /// Mencatat id mana saja yang ditandai bersih — bukti penandaan PER BARIS.
  final List<int> syncedIds = [];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return (notes: List.of(_items), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> getNote(int id) async {
    for (final item in _items) {
      if (item.id == id) return (note: item, failure: null);
    }
    return (note: null, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> insertNote(Note note) async {
    final stored = Note(
      id: _items.length + 1,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: note.dirty,
    );
    _items.add(stored);
    return (note: stored, failure: null);
  }

  @override
  Future<({bool ok, Failure? failure})> updateNote(Note note) async {
    final index = _items.indexWhere((item) => item.id == note.id);
    if (index != -1) _items[index] = note;
    return (ok: true, failure: null);
  }

  @override
  Future<({bool ok, Failure? failure})> deleteNote(int id) async {
    _items.removeWhere((item) => item.id == id);
    return (ok: true, failure: null);
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchDirty() async {
    // Antrean: perubahan TERLAMA lebih dulu, sama seperti query aslinya.
    final dirty = _items.where((item) => item.dirty).toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return (notes: dirty, failure: null);
  }

  @override
  Future<({bool ok, Failure? failure})> markSynced(int id) async {
    syncedIds.add(id);
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return (ok: true, failure: null);
    final old = _items[index];
    _items[index] = Note(
      id: old.id,
      title: old.title,
      body: old.body,
      updatedAt: old.updatedAt,
      dirty: false,
    );
    return (ok: true, failure: null);
  }
}

void main() {
  test('NoteModel.fromMap aman terhadap field yang hilang', () {
    final model = NoteModel.fromMap({'title': 'Belanja'});
    expect(model.title, 'Belanja');
    expect(model.body, '');
    expect(model.dirty, isFalse);
    expect(model.id, isNull);
  });

  test('flag dirty bertahan pada serialisasi', () {
    final model = NoteModel(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );
    final restored = NoteModel.fromMap(model.toMap());
    expect(restored.dirty, isTrue);
    expect(restored.updatedAt, model.updatedAt);
  });

  test('SyncNotes mengirim hanya catatan dirty, satu per satu', () async {
    final repo = FakeNoteRepository(
      items: [
        Note(id: 1, title: 'a', updatedAt: DateTime(2026, 10, 13), dirty: true),
        Note(id: 2, title: 'b', updatedAt: DateTime(2026, 10, 13)),
        Note(id: 3, title: 'c', updatedAt: DateTime(2026, 10, 13), dirty: true),
      ],
    );

    final result = await SyncNotes(repo).call();

    expect(result.synced, 2);
    expect(repo.syncedIds, [1, 3], reason: 'hanya catatan dirty yang dikirim');
  });

  test('SyncNotes tidak melakukan apa-apa saat antrean kosong', () async {
    final repo = FakeNoteRepository(
      items: [Note(id: 1, title: 'a', updatedAt: DateTime(2026, 10, 13))],
    );

    final result = await SyncNotes(repo).call();

    expect(result.synced, 0);
    expect(repo.syncedIds, isEmpty);
  });

  test('provider sukses dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(
            items: [
              Note(id: 1, title: 'Tes', updatedAt: DateTime(2026, 10, 13)),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notes = await container.read(notesProvider.future);

    expect(notes, hasLength(1));
    expect(notes.single.title, 'Tes');
    expect(container.read(dirtyCountProvider), 0);
  });

  test('provider error dengan repository palsu', () async {
    // Riverpod 3 mencoba ulang provider yang gagal (sampai 10x dengan backoff),
    // sehingga `.future` menggantung alih-alih melempar. `retry: null`
    // mematikan percobaan ulang itu.
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(throwError: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(notesProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}
