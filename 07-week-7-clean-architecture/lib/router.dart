import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/notes/presentation/pages/note_detail_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/preferences/presentation/pages/settings_page.dart';

/// Router aplikasi. Dijadikan provider supaya bisa di-`ref.watch` di
/// `MaterialApp.router` dan mudah diganti saat testing.
///
/// Fitur berkomunikasi lewat rute, bukan dengan saling mengimpor halaman.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const NotesPage()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
      GoRoute(
        path: '/note/:id',
        builder: (context, state) => NoteDetailPage(
          // tryParse, bukan parse: URL rusak seperti `/note/abc` menghasilkan
          // null dan ditampilkan sebagai "Catatan tidak ditemukan", bukan crash.
          noteId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
    ],
  );
});
