import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ============================================================
// ShellScreen — scaffold dengan NavigationBar yang SHARED
// untuk semua halaman.
//
// Menggunakan GoRouter ShellRoute:
// - NavigationBar tetap tampil di semua halaman
// - Pindah halaman tidak kehilangan bottom nav
// - State halaman tetap terjaga (IndexedStack behavior)
// ============================================================

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Tentukan index aktif berdasarkan path route saat ini
    final currentPath = GoRouterState.of(context).uri.toString();
    final selectedIndex = currentPath == '/stats' ? 1 : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/');
          } else if (index == 1) {
            context.go('/stats');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
        ],
      ),
    );
  }
}
