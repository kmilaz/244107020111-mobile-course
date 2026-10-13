import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/preferences/presentation/providers/preferences_providers.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
    // Mencatat waktu buka lewat provider, bukan `PreferencesRepositoryImpl()`
    // langsung: instansiasi repository tidak boleh terjadi di luar wiring DI.
    WidgetsBinding.instance.addPostFrameCallback((_) => _markOpened());
  }

  Future<void> _markOpened() async {
    await ref.read(preferencesRepositoryProvider).markOpenedNow();
    // Nilai "terakhir dibuka" berubah → segarkan pembacanya.
    ref.invalidate(lastOpenedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider).value ?? false;

    return MaterialApp.router(
      title: 'Offline Notes',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: darkMode ? Brightness.dark : Brightness.light,
      ),
      // Navigasi diserahkan ke GoRouter (routerProvider), bukan ke `home:`.
      routerConfig: ref.watch(routerProvider),
    );
  }
}
