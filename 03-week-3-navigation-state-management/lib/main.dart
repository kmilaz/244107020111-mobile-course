import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/todo_page.dart';
import 'pages/stats_page.dart';
import 'pages/shell_screen.dart';

// ============================================================
// GoRouter — router deklaratif untuk navigasi multi-page.
//
// Menggunakan ShellRoute agar NavigationBar tetap tampil
// di semua halaman (shared bottom nav).
// ============================================================

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        // ShellRoute → membungkus halaman dengan NavigationBar bersama
        ShellRoute(
          builder: (context, state, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TodoPage(),
            ),
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsPage(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Week 3 - ToDo',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      routerConfig: router,
    );
  }
}