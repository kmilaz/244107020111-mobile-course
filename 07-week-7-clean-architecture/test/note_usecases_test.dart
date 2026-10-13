import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_week_7/core/failures.dart';
import 'package:mobile_week_7/core/format.dart';
import 'package:mobile_week_7/features/notes/domain/entities/note.dart';
import 'package:mobile_week_7/features/notes/domain/repositories/note_repository.dart';
import 'package:mobile_week_7/features/notes/domain/usecases/add_note.dart';
import 'package:mobile_week_7/features/notes/domain/usecases/update_note.dart';

/// Repository palsu yang **merekam** apa yang dikirim use case.
///
/// Begitulah cara menguji aturan domain tanpa database: yang diperiksa bukan isi
/// SQLite, melainkan entity yang diterima repository.
class RecordingNoteRepository implements NoteRepository {
  Note? inserted;
  Note? updated;
  Failure? failWith;

  @override
  Future<({Note? note, Failure? failure})> insertNote(Note note) async {
    if (failWith != null) return (note: null, failure: failWith);
    inserted = note;
    return (note: note, failure: null);
  }

  @override
  Future<({bool ok, Failure? failure})> updateNote(Note note) async {
    if (failWith != null) return (ok: false, failure: failWith);
    updated = note;
    return (ok: true, failure: null);
  }

  // Sisa kontrak tidak dipakai pada test ini.
  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: const <Note>[], failure: null);

  @override
  Future<({Note? note, Failure? failure})> getNote(int id) async =>
      (note: null, failure: null);

  @override
  Future<({bool ok, Failure? failure})> deleteNote(int id) async =>
      (ok: true, failure: null);

  @override
  Future<({List<Note> notes, Failure? failure})> fetchDirty() async =>
      (notes: const <Note>[], failure: null);

  @override
  Future<({bool ok, Failure? failure})> markSynced(int id) async =>
      (ok: true, failure: null);
}

void main() {
  group('AddNote (aturan: judul tidak kosong, wajib dirty)', () {
    test('menolak judul kosong tanpa menyentuh repository', () async {
      final repo = RecordingNoteRepository();

      final result = await AddNote(repo).call(title: '   ');

      expect(result.failure, isA<LocalFailure>());
      expect(result.note, isNull);
      expect(repo.inserted, isNull, reason: 'aturan ditolak sebelum simpan');
    });

    test('catatan baru selalu bertanda dirty dan judulnya di-trim', () async {
      final repo = RecordingNoteRepository();

      final result = await AddNote(repo)
          .call(title: '  Belanja ', body: 'susu');

      expect(result.failure, isNull);
      expect(repo.inserted?.title, 'Belanja');
      expect(repo.inserted?.body, 'susu');
      expect(repo.inserted?.dirty, isTrue);
    });

    test('meneruskan Failure dari repository tanpa melempar', () async {
      final repo = RecordingNoteRepository()
        ..failWith = const LocalFailure('database penuh');

      final result = await AddNote(repo).call(title: 'a');

      expect(result.failure?.message, 'database penuh');
      expect(result.note, isNull);
    });
  });

  group('UpdateNote (aturan: updatedAt = now, wajib dirty)', () {
    test('menolak catatan yang belum tersimpan di database', () async {
      final repo = RecordingNoteRepository();

      final result = await UpdateNote(repo).call(
        note: Note(title: 'a', updatedAt: DateTime(2026)),
        title: 'b',
        body: '',
      );

      expect(result.failure, isA<LocalFailure>());
      expect(repo.updated, isNull);
    });

    test('memakai waktu sekarang dan menandai dirty', () async {
      final repo = RecordingNoteRepository();
      final before = DateTime.now();

      final result = await UpdateNote(repo).call(
        note: Note(id: 7, title: 'lama', updatedAt: DateTime(2020)),
        title: 'baru',
        body: 'isi',
      );

      expect(result.ok, isTrue);
      expect(repo.updated?.id, 7);
      expect(repo.updated?.title, 'baru');
      expect(repo.updated?.dirty, isTrue);
      // updatedAt tidak boleh memakai nilai lama: dasar aturan konflik.
      expect(repo.updated!.updatedAt.isBefore(before), isFalse);
    });
  });

  group('core/format (fungsi murni, diuji tanpa widget)', () {
    test('bentuk keluaran sesuai yang dipakai UI', () {
      final time = DateTime(2026, 10, 13, 8, 5);

      expect(formatShortDateTime(time), '13/10 8:05');
      expect(formatCacheStamp(time), ' 13/10 8:05');
      expect(formatFullDateTime(time), '13/10/2026 8:05');
    });

    test('stempel kosong atau rusak tidak melempar', () {
      expect(formatStoredTimestamp(null), 'belum tercatat');
      expect(formatStoredTimestamp('bukan-tanggal'), 'bukan-tanggal');
    });
  });
}
