import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);      // watch: ikut berubah
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
            subtitle: Text(_formatLastOpened(lastOpened.value)),
          ),
        ],
      ),
    );
  }
}

String _formatLastOpened(String? raw) {
  if (raw == null) return 'belum tercatat';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;                       // data rusak → tampilkan apa adanya
  final m = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour}:$m';
}