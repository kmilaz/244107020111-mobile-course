import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/post_list_page.dart';
import 'pages/paged_post_page.dart';
import 'pages/post_detail_page.dart';
import 'data/models/post.dart';

// =============================================================================
// GoRouter — Routing deklaratif berbasis URL
// =============================================================================
// Kenapa GoRouter, bukan Navigator 1.0?
// - URL berubah otomatis: /post/5, /paged, dll
// - Deep link: user bisa share URL /post/5 langsung
// - ShellRoute: bottom nav persisten (tidak rebuild saat ganti tab)
// - Declarative: route didefinisikan sebagai data, bukan imperative push/pop

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/paged',
    routes: [
      // Halaman daftar post (tanpa pagination)
      GoRoute(
        path: '/',
        name: 'posts',
        builder: (context, state) => const PostListPage(),
      ),
      // Halaman daftar post dengan pagination
      GoRoute(
        path: '/paged',
        name: 'paged',
        builder: (context, state) => const PagedPostPage(),
      ),
      // Halaman detail post — /post/:id
      // extra: data Post dari halaman sebelumnya (bisa null jika buka langsung)
      GoRoute(
        path: '/post/:id',
        name: 'post-detail',
        builder: (context, state) {
          // Ambil path parameter "id" dari URL
          final id = int.parse(state.pathParameters['id'] ?? '0');
          // Ambil data Post dari extra (dikirim dari halaman list)
          final post = state.extra as Post?;
          return PostDetailPage(postId: id, post: post);
        },
      ),
    ],
  );
});

// =============================================================================
// App Entry Point
// =============================================================================

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ProviderScope → Riverpod bisa dipakai di seluruh app
    // MaterialApp.router → menggunakan GoRouter untuk navigasi
    return MaterialApp.router(
      title: 'Week 4 - REST API',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      // routerConfig → GoRouter mengatur semua route
      routerConfig: ref.watch(routerProvider),
    );
  }
}