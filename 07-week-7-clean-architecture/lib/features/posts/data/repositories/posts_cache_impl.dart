import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_cache.dart';
import '../models/post_model.dart';

/// Implementasi cache posts di tabel `cached_posts`.
class PostsCacheImpl implements PostsCache {
  PostsCacheImpl(this._openDb);

  final Future<Database> Function() _openDb;

  @override
  Future<({List<Post> posts, Failure? failure})> read() async {
    try {
      final db = await _openDb();
      final rows = await db.query('cached_posts', orderBy: 'id ASC');
      final posts = rows
          .map(
            (row) => PostModel.fromJson(
              jsonDecode(row['payload'] as String) as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
      return (posts: posts, failure: null);
    } catch (e) {
      return (
        posts: const <Post>[],
        failure: LocalFailure('Gagal membaca cache posts: $e'),
      );
    }
  }

  @override
  Future<({DateTime? cachedAt, Failure? failure})> lastCachedAt() async {
    try {
      final db = await _openDb();
      final rows = await db.rawQuery(
        'SELECT MAX(cached_at) AS cached_at FROM cached_posts',
      );
      final value = rows.first['cached_at'] as String?;
      return (
        cachedAt: value == null ? null : DateTime.tryParse(value),
        failure: null,
      );
    } catch (e) {
      return (
        cachedAt: null,
        failure: LocalFailure('Gagal membaca waktu cache: $e'),
      );
    }
  }

  @override
  Future<({bool ok, Failure? failure})> replaceAll(List<Post> posts) async {
    try {
      final db = await _openDb();
      final now = DateTime.now().toIso8601String();
      // batch = N insert dalam SATU transaksi.
      final batch = db.batch();
      for (final post in posts) {
        batch.insert('cached_posts', {
          'id': post.id,
          'payload': jsonEncode(
            PostModel(id: post.id, title: post.title, body: post.body).toJson(),
          ),
          'cached_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      return (ok: true, failure: null);
    } catch (e) {
      return (ok: false, failure: LocalFailure('Gagal menyimpan cache: $e'));
    }
  }
}
