import 'package:flutter/material.dart';

/// Halaman tujuan deep link. Dibuka dari klik notifikasi (foreground,
/// background, maupun terminated) maupun dari tombol uji di beranda.
class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengumuman #$id',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text('Jadwal kuliah berubah'),
            const SizedBox(height: 4),
            const Text('Kelas Mobile pindah ke Ruang A2 jam 13.00'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Halaman ini dibuka lewat rute ${'/pengumuman/$id'}. '
                'Kalau kamu sampai di sini dengan menekan notifikasi, '
                'berarti deep link dari data payload berhasil.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
