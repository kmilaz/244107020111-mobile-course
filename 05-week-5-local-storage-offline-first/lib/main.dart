import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/prefs.dart';
import 'data/providers.dart';
import 'pages/notes_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PrefsRepository().markOpenedNow();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider).value ?? false;

    return MaterialApp(
      title: 'Offline Notes',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: darkMode ? Brightness.dark : Brightness.light,
      ),
      home: const NotesPage(),
    );
  }
}
