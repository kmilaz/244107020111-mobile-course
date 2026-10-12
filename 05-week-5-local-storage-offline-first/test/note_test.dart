import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_week_5/data/local/note.dart';
import 'package:mobile_week_5/data/providers.dart';
import 'package:mobile_week_5/data/repositories/note_repository.dart';
import 'package:mobile_week_5/data/sync.dart';

/// Repository palsu: TIDAK menyentuh SQLite sama sekali.
///
/// `openDb` sengaja diisi fungsi yang melempar — kabel jebakan. Kalau ada jalur
/// kode yang mencoba membuka database sungguhan, test langsung gagal keras
/// (di `flutter test` plugin sqflite tidak ada → `MissingPluginException`).
class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({List<Note> items = const [], this.throwError = false})
    : _items = [...items],
      super(openDb: () => throw UnimplementedError());

  final List<Note> _items;
  final bool throwError;

  /// Mencatat id mana saja yang ditandai bersih.
  /// Inilah bukti bahwa penandaan dilakukan PER BARIS, bukan sekaligus.
  final List<int> syncedIds = [];

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return List.of(_items);
  }

  @override
  Future<int> countDirty() async => _items.where((note) => note.dirty).length;

  @override
  Future<List<Note>> fetchDirty() async {
    // Antrean: perubahan TERLAMA lebih dulu (ASC), sama seperti query asli.
    final dirty = _items.where((note) => note.dirty).toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return dirty;
  }

  @override
  Future<void> markSynced(int id) async {
    syncedIds.add(id);
    final index = _items.indexWhere((note) => note.id == id);
    if (index == -1) return;
    // Note tidak punya copyWith, jadi objek baru dibuat manual.
    final old = _items[index];
    _items[index] = Note(
      id: old.id,
      title: old.title,
      body: old.body,
      updatedAt: old.updatedAt,
      dirty: false,
    );
  }
}

void main() {
  test('fromMap aman terhadap field yang hilang', () {
    final note = Note.fromMap({'title': 'Belanja'});
    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
    expect(note.id, isNull);
  });

  test('flag dirty bertahan pada serialisasi', () {
    final note = Note(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );
    final restored = Note.fromMap(note.toMap());
    expect(restored.dirty, isTrue);
    expect(restored.updatedAt, note.updatedAt);
  });

  test('syncNotes mengirim hanya catatan dirty, satu per satu', () async {
    final repo = FakeNoteRepository(
      items: [
        Note(id: 1, title: 'a', updatedAt: DateTime(2026, 10, 13), dirty: true),
        Note(id: 2, title: 'b', updatedAt: DateTime(2026, 10, 13)),
        Note(id: 3, title: 'c', updatedAt: DateTime(2026, 10, 13), dirty: true),
      ],
    );

    final synced = await syncNotes(repo);

    expect(synced, 2);
    expect(repo.syncedIds, [1, 3], reason: 'hanya catatan dirty yang dikirim');
    expect(
      await repo.fetchDirty(),
      isEmpty,
      reason: 'antrean kosong setelah sync',
    );
  });

  test('syncNotes tidak melakukan apa-apa saat antrean kosong', () async {
    final repo = FakeNoteRepository(
      items: [Note(id: 1, title: 'a', updatedAt: DateTime(2026, 10, 13))],
    );

    expect(await syncNotes(repo), 0);
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
    expect(await container.read(dirtyCountProvider.future), 0);
  });

  test('provider error dengan repository palsu', () async {
    final container = ProviderContainer(
      // Riverpod 3 mencoba ulang provider yang gagal (sampai 10x dengan
      // backoff), sehingga `.future` MENGGANTUNG alih-alih melempar, dan test
      // berakhir "timed out". `retry: (_, _) => null` mematikan percobaan ulang
      // itu. Test versi codelab ditulis untuk Riverpod 2 yang tidak punya retry.
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
