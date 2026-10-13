import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../providers/preferences_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider); // watch: ikut berubah
    final lastOpened = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Tema gelap'),
            subtitle: const Text('Disimpan di SharedPreferences'),
            value: darkMode.value ?? false,
            // Nonaktif selama loading: jangan izinkan aksi sebelum state siap.
            onChanged: darkMode.isLoading
                ? null
                : (_) => ref.read(darkModeProvider.notifier).toggle(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Terakhir dibuka'),
            // Formatting tanggal dari lib/core/format.dart (fungsi murni).
            subtitle: Text(formatStoredTimestamp(lastOpened.value)),
          ),
        ],
      ),
    );
  }
}
