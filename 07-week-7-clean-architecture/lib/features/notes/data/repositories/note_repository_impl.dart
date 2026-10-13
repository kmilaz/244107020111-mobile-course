import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

/// Implementasi kontrak [NoteRepository] memakai SQLite.
///
/// Tugasnya hanya dua: menyimpan/membaca data, dan **mengubah exception menjadi
/// `Failure`** supaya tidak ada exception mentah yang sampai ke presentation.
/// Aturan bisnis tidak ada di sini — itu milik use case di domain.
class NoteRepositoryImpl implements NoteRepository {
  /// Fungsi pembuka database disuntikkan dari luar (di-wire di provider Riverpod)
  /// supaya implementasi ini mudah diganti repository palsu saat test.
  NoteRepositoryImpl(this._openDb);

  final Future<Database> Function() _openDb;

  static Note _toEntity(Map<String, Object?> row) =>
      NoteModel.fromMap(row).toEntity();

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await _openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      return (notes: rows.map(_toEntity).toList(), failure: null);
    } catch (e) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> getNote(int id) async {
    try {
      final db = await _openDb();
      final rows = await db.query(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      // "Tidak ada" adalah keadaan yang sah, bukan kegagalan.
      if (rows.isEmpty) return (note: null, failure: null);
      return (note: _toEntity(rows.first), failure: null);
    } catch (e) {
      return (note: null, failure: LocalFailure('Gagal membaca catatan: $e'));
    }
  }

  @override
  Future<({Note? note, Failure? failure})> insertNote(Note note) async {
    try {
      final db = await _openDb();
      final id = await db.insert(
        'notes',
        NoteModel(
          title: note.title,
          body: note.body,
          updatedAt: note.updatedAt,
          dirty: note.dirty,
        ).toMap(),
      );
      return (
        note: Note(
          id: id,
          title: note.title,
          body: note.body,
          updatedAt: note.updatedAt,
          dirty: note.dirty,
        ),
        failure: null,
      );
    } catch (e) {
      return (note: null, failure: LocalFailure('Gagal menyimpan catatan: $e'));
    }
  }

  @override
  Future<({bool ok, Failure? failure})> updateNote(Note note) async {
    final id = note.id;
    if (id == null) {
      // Tanpa guard ini, `WHERE id = null` tidak cocok dengan baris mana pun dan
      // update gagal DIAM-DIAM.
      return (
        ok: false,
        failure: const LocalFailure('Catatan belum tersimpan di database'),
      );
    }
    try {
      final db = await _openDb();
      await db.update(
        'notes',
        NoteModel(
          id: id,
          title: note.title,
          body: note.body,
          updatedAt: note.updatedAt,
          dirty: note.dirty,
        ).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      return (ok: true, failure: null);
    } catch (e) {
      return (ok: false, failure: LocalFailure('Gagal menyimpan catatan: $e'));
    }
  }

  @override
  Future<({bool ok, Failure? failure})> deleteNote(int id) async {
    try {
      final db = await _openDb();
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      return (ok: true, failure: null);
    } catch (e) {
      return (ok: false, failure: LocalFailure('Gagal menghapus catatan: $e'));
    }
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    try {
      final db = await _openDb();
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1',
      );
      return (count: (rows.first['c'] as num?)?.toInt() ?? 0, failure: null);
    } catch (e) {
      return (count: 0, failure: LocalFailure('Gagal menghitung antrean: $e'));
    }
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchDirty() async {
    try {
      final db = await _openDb();
      // Perubahan TERLAMA lebih dulu: antrean dikirim berurutan.
      final rows = await db.query(
        'notes',
        where: 'dirty = 1',
        orderBy: 'updated_at ASC',
      );
      return (notes: rows.map(_toEntity).toList(), failure: null);
    } catch (e) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca antrean: $e'),
      );
    }
  }

  @override
  Future<({bool ok, Failure? failure})> markSynced(int id) async {
    try {
      final db = await _openDb();
      await db.update('notes', {'dirty': 0}, where: 'id = ?', whereArgs: [id]);
      return (ok: true, failure: null);
    } catch (e) {
      return (
        ok: false,
        failure: LocalFailure('Gagal menandai tersinkron: $e'),
      );
    }
  }
}
