import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'models/post.dart';
import 'repositories/note_repository.dart';

/// Plumbing offline-first yang bukan milik repository mana pun:
/// cache baca (`cached_posts`) dan antrean tulis (`syncNotes`).
///
/// Dipisahkan ke file ini (Refactoring Challenge #2) supaya `NoteRepository`
/// tetap fokus pada CRUD dan `PostRepository` tetap menjadi sumber remote murni.

/// Baca/tulis tabel `cached_posts` — separuh "baca" dari offline-first.
class PostsCache {
  PostsCache({Future<Database> Function()? openDb})
    : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  Future<List<Post>> read() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows
        .map(
          (row) => Post.fromJson(
            jsonDecode(row['payload'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<DateTime?> lastCachedAt() async {
    final db = await _openDb();
    final rows = await db.rawQuery(
      'SELECT MAX(cached_at) AS cached_at FROM cached_posts',
    );
    final value = rows.first['cached_at'] as String?;
    return value == null ? null : DateTime.tryParse(value);
  }

  /// Timpa seluruh cache. `batch` = N insert dalam satu transaksi.
  Future<void> replaceAll(List<Post> posts) async {
    final db = await _openDb();
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final post in posts) {
      batch.insert('cached_posts', {
        'id': post.id,
        'payload': jsonEncode(post.toJson()),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}

/// Antrean tulis: mengirim catatan yang masih `dirty` ke "server".
///
/// Setiap catatan ditandai bersih **sendiri-sendiri, setelah "upload"-nya
/// berhasil** — bukan lewat `markAllSynced()` seperti contoh codelab.
///
/// Alasannya: `markAllSynced()` menandai SEMUA baris dirty jadi bersih
/// sekaligus, sehingga bila server menolak sebagian catatan, catatan yang gagal
/// ikut dianggap terkirim dan tidak akan pernah dicoba lagi (kehilangan data
/// senyap — badge berkata "semua tersinkron" padahal tidak).
///
/// Project nyata: ganti `Future.delayed` dengan request sungguhan, dan taruh
/// `markSynced(id)` hanya pada respons 2xx.
Future<int> syncNotes(NoteRepository repo) async {
  final pending = await repo.fetchDirty(); // urut: perubahan terlama dulu
  var synced = 0;

  for (final note in pending) {
    final id = note.id;
    if (id == null) continue;

    await Future.delayed(const Duration(milliseconds: 300)); // simulasi upload
    await repo.markSynced(id); // bersihkan HANYA baris ini
    synced++;
  }

  return synced;
}
