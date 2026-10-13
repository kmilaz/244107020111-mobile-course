import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../local/note.dart';

/// Satu-satunya pintu ke tabel `notes`.
///
/// Antrean sync (`syncNotes`) tinggal di `lib/data/sync.dart` supaya class ini
/// tetap fokus pada CRUD.
class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
    : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> addNote({required String title, String body = ''}) async {
    final db = await _openDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    final id = await db.insert('notes', note.toMap());
    return Note(
      id: id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: true,
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countDirty() async {
    final db = await _openDb();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1',
    );
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

  /// Catatan yang menunggu dikirim, perubahan TERLAMA lebih dulu — supaya
  /// urutan yang diterima server sama dengan urutan user mengubahnya.
  Future<List<Note>> fetchDirty() async {
    final db = await _openDb();
    final rows = await db.query(
      'notes',
      where: 'dirty = 1',
      orderBy: 'updated_at ASC',
    );
    return rows.map(Note.fromMap).toList();
  }

  /// Tandai SATU catatan bersih. Dipanggil hanya setelah server menerimanya.
  Future<void> markSynced(int id) async {
    final db = await _openDb();
    await db.update('notes', {'dirty': 0}, where: 'id = ?', whereArgs: [id]);
  }

  /// Satu catatan berdasarkan id, atau null bila tidak ada.
  /// "Tidak ada" adalah keadaan yang sah, bukan error.
  Future<Note?> getNote(int id) async {
    final db = await _openDb();
    final rows = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  Future<void> updateNote(Note note) async {
    final id = note.id;
    if (id == null) {
      // Tanpa guard ini, `WHERE id = null` tidak cocok dengan baris mana pun
      // dan update gagal DIAM-DIAM. Lebih baik gagal keras.
      throw ArgumentError(
        'updateNote butuh note yang sudah tersimpan (id != null)',
      );
    }
    final db = await _openDb();
    await db.update(
      'notes',
      {
        'title': note.title,
        'body': note.body,
        'updated_at': note.updatedAt.toIso8601String(),
        'dirty': note.dirty ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
