import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routes.dart';

final FlutterLocalNotificationsPlugin _local =
    FlutterLocalNotificationsPlugin();

/// Deep link yang menunggu sampai router siap (mis. banner diklik saat app
/// belum selesai dibangun).
String? pendingDeepLink;

/// Dipanggil setiap kali ada permintaan deep link. Diisi oleh aplikasi setelah
/// router siap.
void Function(String route)? onDeepLinkRequested;

/// `false` = Firebase belum siap (mis. `google-services.json` belum ada),
/// sehingga seluruh fitur FCM dilewati alih-alih membuat aplikasi crash.
bool firebaseReady = false;

/// FCM token terakhir. Hanya ditampilkan dalam bentuk terpotong.
///
/// Memakai `ValueNotifier` supaya UI ikut berubah begitu token benar-benar
/// terbit: `getToken()` bisa mengembalikan null pada pemanggilan pertama, dan
/// token biasanya baru siap beberapa detik kemudian.
final ValueNotifier<String?> fcmTokenNotifier = ValueNotifier<String?>(null);

/// Handler background **wajib** fungsi top-level dan diberi `@pragma`
/// `vm:entry-point`, karena berjalan di isolate terpisah.
///
/// Di sini TIDAK BOLEH mengakses `BuildContext`, Riverpod, atau state UI.
/// Tugasnya hanya mencatat ringan — navigasi dilakukan saat notifikasi diklik.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'FCM background: id=${message.messageId} route=${message.data['route']}',
    name: 'push',
  );
}

void registerBackgroundHandler() {
  if (!firebaseReady) return;
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

/// Id channel Android untuk pengumuman.
///
/// Nilai ini juga diisikan pada field **"Android Notification Channel"** di
/// Firebase Console, supaya pesan FCM masuk ke channel yang sama dengan banner
/// lokal. Pentingnya HIGH, sehingga notifikasi muncul sebagai banner heads-up —
/// bukan sekadar diam di panel notifikasi.
const String campusChannelId = 'pengumuman';

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      // Klik banner foreground → teruskan payload ke router.
      _dispatchDeepLink(response.payload ?? AppRoutes.home);
    },
  );

  // Channel dibuat sejak awal, bukan menunggu notifikasi pertama, supaya pesan
  // FCM yang pertama datang pun sudah punya channel tujuan.
  await _local
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          campusChannelId,
          'Pengumuman Kampus',
          description: 'Notifikasi pengumuman kampus',
          importance: Importance.high,
        ),
      );
}

void _dispatchDeepLink(String route) {
  final handler = onDeepLinkRequested;
  debugPrint('[PUSH] deep link diminta: $route (handler=${handler != null})');
  if (handler != null) {
    handler(route);
  } else {
    pendingDeepLink = route;
  }
}

/// Android 13+ dan iOS mewajibkan permintaan izin runtime.
///
/// Izin ini diminta lewat `flutter_local_notifications`, **bukan** hanya lewat
/// Firebase: banner foreground ditampilkan oleh plugin itu, jadi izinnya tetap
/// diperlukan walaupun Firebase belum dikonfigurasi.
Future<bool> requestNotificationPermission() async {
  final android = _local
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  final ios = _local
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  var granted = true;
  if (android != null) {
    granted = await android.requestNotificationsPermission() ?? false;
  } else if (ios != null) {
    granted =
        await ios.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  if (!firebaseReady) return granted;

  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return granted &&
      (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional);
}

/// Ambil token sekarang, pantau perubahannya, lalu berlangganan topik kampus.
Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  if (!firebaseReady) return;

  // `getToken()` bisa mengembalikan null pada percobaan pertama karena
  // registrasi FCM belum selesai. Menyerah sekali coba berarti backend tidak
  // pernah menerima token sama sekali — jadi dicoba beberapa kali.
  String? token = await FirebaseMessaging.instance.getToken();
  for (var attempt = 0; token == null && attempt < 6; attempt++) {
    await Future<void>.delayed(const Duration(seconds: 1));
    token = await FirebaseMessaging.instance.getToken();
  }

  if (token != null) {
    fcmTokenNotifier.value = token;
    await onToken(token);
  }

  // WAJIB ada. Tanpa listener ini, token baru (setelah reinstall / clear data /
  // rotasi keamanan) tidak sampai ke backend, sehingga server menyimpan token
  // basi dan notifikasi berhenti terkirim tanpa error apa pun.
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    fcmTokenNotifier.value = newToken;
    onToken(newToken);
  });

  await subscribeToTopic('pengumuman-kampus');
}

Future<void> subscribeToTopic(String topic) async {
  if (!firebaseReady) return;
  await FirebaseMessaging.instance.subscribeToTopic(topic);
  debugPrint('[PUSH] berlangganan topik: $topic');
}

Future<void> unsubscribeFromTopic(String topic) async {
  if (!firebaseReady) return;
  await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  debugPrint('[PUSH] berhenti dari topik: $topic');
}

/// Menampilkan banner lokal. Dipakai untuk dua hal:
/// 1. foreground FCM — sistem TIDAK menampilkan banner otomatis, jadi harus manual;
/// 2. simulasi di dalam aplikasi, supaya alur banner + deep link bisa diuji
///    tanpa project Firebase.
Future<void> showLocalBanner({
  required String title,
  required String body,
  required String route,
}) async {
  const androidDetails = AndroidNotificationDetails(
    campusChannelId,
    'Pengumuman Kampus',
    channelDescription: 'Notifikasi pengumuman kampus',
    importance: Importance.high,
    priority: Priority.high,
  );
  await _local.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: androidDetails),
    payload: route,
  );
}

void listenForeground(void Function(String route) go) {
  if (!firebaseReady) return;

  // Foreground: tampilkan manual, karena banner otomatis hanya muncul saat
  // aplikasi di background/terminated.
  FirebaseMessaging.onMessage.listen((message) async {
    debugPrint('[PUSH] pesan diterima (foreground): ${message.data}');
    await showLocalBanner(
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      route: routeFromMessage(message.data),
    );
  });

  // Background → banner diklik.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(routeFromMessage(message.data));
  });
}

/// Terminated → aplikasi dibuka dari notifikasi.
Future<void> handleTerminated(void Function(String route) go) async {
  if (firebaseReady) {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) go(routeFromMessage(initial.data));
  }
  final pending = pendingDeepLink;
  if (pending != null) {
    pendingDeepLink = null;
    go(pending);
  }
}
