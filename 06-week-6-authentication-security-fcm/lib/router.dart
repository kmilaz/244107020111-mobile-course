import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

/// Router aplikasi, lengkap dengan **guard route**: pengguna yang belum login
/// selalu diarahkan ke `/login`, dan yang sudah login tidak bisa kembali ke
/// halaman login.
final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter perlu "sinyal" agar redirect dievaluasi ulang saat status login
  // berubah. Tanpa ini, setelah login aplikasi tidak berpindah halaman.
  final authListenable = ValueNotifier<bool>(false);
  ref.listen(authStateProvider, (_, next) {
    authListenable.value = next.value ?? false;
  });
  ref.onDispose(authListenable.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final loggedIn = ref.read(authStateProvider).value ?? false;
      final goingToLogin = state.matchedLocation == AppRoutes.login;

      if (!loggedIn && !goingToLogin) return AppRoutes.login;
      if (loggedIn && goingToLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (context, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
