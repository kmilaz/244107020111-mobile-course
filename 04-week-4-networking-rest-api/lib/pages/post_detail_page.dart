/// Halaman detail post — menampilkan judul dan isi lengkap.
///
/// Dua cara data bisa sampai ke halaman ini:
/// 1. Dari list (PostListPage / PagedPostPage) → data Post di-pass lewat GoRouter extra
/// 2. Buka langsung via URL /post/:id → fetch dari repository berdasarkan postId
///
/// Ini penting karena:
/// - Cara 1: hemat API call, data sudah ada di memori
/// - Cara 2: user bisa share link langsung ke post tertentu
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post.dart';
import '../data/providers.dart';

/// Halaman detail post.
///
/// [postId] → ID post dari URL path (/post/:id)
/// [post] → data Post dari halaman sebelumnya (opsional, bisa null)
class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    this.post,
  });

  /// ID post dari URL path parameter
  final int postId;

  /// Data post dari halaman sebelumnya (null jika buka langsung via URL)
  final Post? post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Jika data post sudah ada (dari halaman list) → pakai langsung
    // Jika null (buka langsung via URL) → fetch dari repository
    if (post != null) {
      return _buildDetail(post!);
    }

    // Ambil data dari provider (sudah di-cache oleh halaman list)
    final postsAsync = ref.watch(postListProvider);
    return postsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Gagal memuat data: $err')),
      ),
      data: (posts) {
        // Cari post berdasarkan ID dari list yang sudah dimuat
        final found = posts.where((p) => p.id == postId).firstOrNull;
        if (found != null) {
          return _buildDetail(found);
        }
        // Jika tidak ditemukan di cache, tampilkan pesan
        return Scaffold(
          appBar: AppBar(title: const Text('Tidak ditemukan')),
          body: const Center(
            child: Text('Post tidak ditemukan di daftar.'),
          ),
        );
      },
    );
  }

  /// Membangun tampilan detail post.
  Widget _buildDetail(Post p) {
    return Scaffold(
      appBar: AppBar(title: Text('Post #${p.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul post dengan gaya heading
            Text(
              p.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Info postingan
            Text(
              'Post #${p.id} • User ${p.userId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 32),
            // Isi post lengkap (tanpa limit)
            Text(
              p.body,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
