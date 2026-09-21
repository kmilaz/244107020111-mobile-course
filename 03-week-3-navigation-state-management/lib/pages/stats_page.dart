import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// ============================================================
// StatsPage — ConsumerWidget yang menampilkan data statistik.
//
// Menggunakan AsyncValue.when() untuk menangani 3 kondisi:
// 1. AsyncLoading  → spinner saat data sedang dimuat
// 2. AsyncError    → pesan error + tombol "Coba lagi"
// 3. AsyncData     → tampilkan list 3 item statistik
// ============================================================

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch — membangun ulang widget saat statsProvider berubah.
    // Return type: AsyncValue<TodoStats>
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik ToDo')),
      body: statsAsync.when(
        // =============================================
        // STATE 1: Loading — data belum siap
        // Tampilkan spinner di tengah layar
        // =============================================
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data statistik...'),
            ],
          ),
        ),

        // =============================================
        // STATE 2: Error — pengambilan data gagal
        // Tampilkan pesan error + tombol retry
        // =============================================
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Terjadi kesalahan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                // Tombol "Coba lagi" → memanggil ref.invalidate()
                // yang menjalankan ulang provider (kembali ke loading)
                FilledButton.icon(
                  onPressed: () => ref.invalidate(statsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),

        // =============================================
        // STATE 3: Data — berhasil mendapat data
        // Tampilkan 3 item statistik dalam ListView
        // =============================================
        data: (stats) {
          // List data statistik yang akan ditampilkan
          final items = [
            _StatItem(
              icon: Icons.list_alt,
              label: 'Total Tugas',
              value: '${stats.total}',
              color: Colors.blue,
            ),
            _StatItem(
              icon: Icons.check_circle_outline,
              label: 'Selesai',
              value: '${stats.done}',
              color: Colors.green,
            ),
            _StatItem(
              icon: Icons.pending_outlined,
              label: 'Belum Selesai',
              value: '${stats.remaining}',
              color: Colors.orange,
            ),
          ];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.color.withValues(alpha: 0.15),
                    child: Icon(item.icon, color: item.color),
                  ),
                  title: Text(item.label),
                  trailing: Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // Tombol refresh manual — panggil refresh() pada provider
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(statsProvider.notifier).refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// Helper class untuk menyimpan data item statistik
class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
