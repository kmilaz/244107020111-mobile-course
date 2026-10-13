import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/token_store.dart';
import 'messaging/push_service.dart';
import 'providers/auth_provider.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase dibuat defensif: tanpa `google-services.json`,
  // `Firebase.initializeApp()` akan gagal. Aplikasi TIDAK dibiarkan mati karena
  // itu — hanya fitur FCM yang dinonaktifkan. Cara mengaktifkannya ada di README.
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (error, stack) {
    firebaseReady = false;
    developer.log(
      'Firebase belum siap, fitur FCM dinonaktifkan. Lihat README bagian '
      '"Mengaktifkan FCM". Penyebab: $error',
      name: 'push',
      error: error,
      stackTrace: stack,
    );
  }

  registerBackgroundHandler();
  await initLocalNotifications();

  runApp(const ProviderScope(child: CampusNotifyApp()));
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  @override
  void initState() {
    super.initState();
    // Setup FCM setelah frame pertama: butuh router dan secure storage siap.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPush());
  }

  Future<void> _initPush() async {
    // Klik banner (foreground) dan klik dari state lain sama-sama berakhir
    // di router.
    onDeepLinkRequested = _go;

    final granted = await requestNotificationPermission();
    developer.log('Izin notifikasi diberikan: $granted', name: 'push');

    await initFcmToken(
      onToken: (token) async {
        // Token utuh TIDAK dicatat ke log — hanya versi terpotong.
        developer.log(
          'FCM token (terpotong): ${TokenStore.mask(token)}',
          name: 'push',
        );
        try {
          await ref
              .read(apiClientProvider)
              .post(
                '/devices',
                data: {
                  'fcm_token': token,
                  'platform': Platform.isAndroid ? 'android' : 'ios',
                },
              );
        } catch (error) {
          // Endpoint backend kampus belum ada di codelab ini. Kegagalannya
          // diabaikan supaya aplikasi tetap jalan; ganti baseUrl di
          // api_client.dart dengan API kampus yang sesungguhnya.
          developer.log('POST /devices gagal: $error', name: 'push');
        }
      },
    );

    listenForeground(_go);
    await handleTerminated(_go);
  }

  void _go(String route) {
    debugPrint('[PUSH] navigasi ke: $route');
    if (!mounted) return;
    ref.read(routerProvider).go(route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    // Tunggu status login terbaca lebih dulu, supaya guard route tidak sempat
    // melempar ke /login padahal sesi masih tersimpan di secure storage.
    if (auth.isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
