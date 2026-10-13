import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../providers/posts_providers.dart';

/// Bagian daftar posts hasil cache-first.
///
/// Dipisah dari halaman catatan supaya tiap fitur memiliki widget-nya sendiri —
/// halaman catatan tidak perlu tahu apa pun soal `PostsState`.
class PostsSection extends ConsumerWidget {
  const PostsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Posts (cache-first)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_label(posts), style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Muat ulang',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(postsProvider.notifier).load(),
              ),
            ],
          ),
        ),
        if (posts.isLoading) const LinearProgressIndicator(),
        Expanded(
          child: posts.posts.isEmpty
              ? const Center(child: Text('Belum ada posts. Tekan muat ulang.'))
              : ListView.builder(
                  itemCount: posts.posts.length,
                  itemBuilder: (context, index) {
                    final post = posts.posts[index];
                    return ListTile(
                      dense: true,
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Menjelaskan dari mana data di layar berasal.
  String _label(PostsState state) {
    final cachedAt = state.lastCachedAt;
    final stamp = cachedAt == null ? '' : formatCacheStamp(cachedAt);

    final base = switch (state.source) {
      PostsSource.none => 'belum dimuat',
      PostsSource.cache => 'dari cache$stamp',
      PostsSource.network => 'dari jaringan$stamp',
    };

    return state.error != null ? '$base - gagal refresh' : base;
  }
}
