/// Widget reusable untuk menampilkan satu baris post dalam daftar.
///
/// Diekstrak dari ListView.builder agar:
/// 1. ListView.builder pendek dan fokus pada logika list
/// 2. PostTile bisa diuji secara terisolasi (widget test)
/// 3. Bisa dipakai ulang di PostListPage DAN PagedPostPage
library;

import 'package:flutter/material.dart';
import '../data/models/post.dart';

class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.post,
    this.onTap,
  });

  /// Data post yang akan ditampilkan.
  final Post post;

  /// Callback saat user mengetuk tile.
  /// Biasanya untuk navigasi ke halaman detail.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(post.id.toString())),
      title: Text(
        post.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        post.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
