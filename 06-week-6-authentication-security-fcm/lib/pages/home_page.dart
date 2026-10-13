import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/token_store.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';

/// Beranda: menunjukkan bukti sesi (token terpotong) dan tombol-tombol uji
/// untuk alur notifikasi serta deep link.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final Future<String?> _accessToken;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _accessToken = ref.read(tokenStoreProvider).readAccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<String?>(
            future: _accessToken,
            builder: (context, snapshot) => _TokenCard(
              label: 'Access token (terpotong)',
              value: TokenStore.mask(snapshot.data),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String?>(
            valueListenable: fcmTokenNotifier,
            builder: (context, token, _) => _TokenCard(
              label: 'FCM token (terpotong)',
              value: !firebaseReady
                  ? 'Firebase belum aktif'
                  : token == null
                  ? 'sedang diminta…'
                  : TokenStore.mask(token),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Uji alur notifikasi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.notifications_active),
            label: const Text('Tampilkan banner (simulasi lokal)'),
            onPressed: () => showLocalBanner(
              title: 'Jadwal kuliah berubah',
              body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
              route: AppRoutes.announcementFor('3'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.link),
            label: const Text('Buka /pengumuman/3'),
            onPressed: () => context.push(AppRoutes.announcementFor('3')),
          ),
          const SizedBox(height: 24),
          const Text('Topik', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            dense: true,
            title: const Text('pengumuman-kampus'),
            subtitle: const Text('Broadcast untuk semua mahasiswa'),
            value: _subscribed,
            onChanged: firebaseReady
                ? (value) async {
                    if (value) {
                      await subscribeToTopic('pengumuman-kampus');
                    } else {
                      await unsubscribeFromTopic('pengumuman-kampus');
                    }
                    if (mounted) setState(() => _subscribed = value);
                  }
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            firebaseReady
                ? 'Firebase aktif. Token di atas dipotong — token utuh tidak '
                      'pernah ditampilkan atau dicatat ke log.'
                : 'Firebase belum aktif, jadi fitur FCM dinonaktifkan. '
                      'Lihat README bagian "Mengaktifkan FCM" untuk '
                      'mengaktifkannya. (Tombol simulasi banner tetap bekerja.)',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TokenCard extends StatelessWidget {
  const _TokenCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 12)),
        subtitle: Text(
          value,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ),
    );
  }
}
