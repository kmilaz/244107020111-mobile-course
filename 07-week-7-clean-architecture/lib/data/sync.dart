import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'models/post.dart';

/// Baca/tulis tabel `cached_posts` — separuh "baca" dari offline-first.
///
/// Antrean tulis (`syncNotes`) sudah pindah ke use case `SyncNotes` di domain
/// fitur `notes`, karena aturan urutan antrean adalah aturan bisnis.
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
