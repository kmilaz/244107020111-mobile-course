# AI Challenge — Authentication, Secure Token & FCM

Praktikum Minggu 6, project `06-week-6-authentication-security-fcm`.

## 1. Prompt yang dipakai

```
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

## 2. Ringkasan output awal AI

Struktur `PushService` yang diusulkan sudah sesuai kebutuhan: izin notifikasi,
siklus token, tiga handler state, topik, dan background handler top-level dengan
`@pragma('vm:entry-point')`. Yang **tidak** benar adalah detail yang hanya muncul
setelah kode dijalankan: beberapa API sudah berubah di versi paket yang terpasang,
satu enum baru membuat `switch` tidak lengkap, dan salah satu builder Gradle tidak
memenuhi syarat plugin.

## 3. Perbaikan manual dan alasan teknisnya

| # | Yang salah di draf | Gejala | Perbaikan | Alasan |
| --- | --- | --- | --- | --- |
| 1 | `flutter_local_notifications` dipanggil dengan argumen **posisional** (`initialize(settings, …)`, `show(id, title, body, details, …)`) | `Too many positional arguments` + `named parameter 'settings' is required` | Ubah ke **named**: `initialize(settings: …)`, `show(id: …, title: …, body: …, notificationDetails: …, payload: …)` | Sejak versi 22 API-nya berpindah ke named parameter. Perhatikan juga `details` berubah nama menjadi `notificationDetails` — nama yang mudah ditebak salah |
| 2 | `switch (error.type)` tanpa `transformTimeout` | `non_exhaustive_switch_statement` | Tambahkan `DioExceptionType.transformTimeout` ke kelompok timeout | Dio 5.11 menambah nilai enum baru. Switch atas enum **wajib** lengkap, dan nilai baru dari paket bisa mematahkannya kapan saja |
| 3 | Gradle belum mengaktifkan core library desugaring | `compileDebugKotlin` gagal / build menolak | `isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` | `flutter_local_notifications` memakai API Java 8+ yang harus di-desugar untuk perangkat Android lama |
| 4 | (lingkungan) `kotlin.incremental` masih aktif | `Could not close incremental caches … RelocatableFileToPathConverter.toPath` | `kotlin.incremental=false` di `android/gradle.properties` | Pub cache di drive `C:` sedangkan project di drive `D:`; cache incremental Kotlin tidak bisa menyusun path relatif antar drive |
| 5 | Interceptor 401 bisa mencoba refresh **berkali-kali** | Potensi lingkaran 401 → "401 berulang meski sudah login" | Tandai `requestOptions.extra['retried'] = true`; kalau sudah pernah, bersihkan sesi dan berhenti | Aturan codelab adalah "refresh **satu kali** lalu retry". Tanpa penanda, request hasil retry yang juga 401 akan memicu refresh lagi, berulang |
| 6 | `routeFromMessage` menerima path apa saja | Payload bisa mengarahkan aplikasi ke luar | Tolak string yang mengandung `://` → kembalikan beranda | Data payload berasal dari luar; jangan sampai bisa dijadikan deep link keluar aplikasi |
| 7 | `Firebase.initializeApp()` tanpa penanganan gagal | Aplikasi **mati total** kalau `google-services.json` belum ada | Bungkus `try/catch`, tandai `firebaseReady`; semua fitur FCM memeriksa flag itu | Supaya project tetap bisa di-build dan dijalankan sebelum Firebase disiapkan. Fitur FCM aktif sendiri setelah flag bernilai `true` |
| 8 | Token ditampilkan/dicatat apa adanya | Token bocor lewat log atau screenshot | `TokenStore.mask()` → hanya 4 karakter awal + 4 karakter akhir | Prinsip keamanan codelab: **tidak log token**. Sekaligus membuat screenshot bukti tetap aman |
| 9 | `getToken()` dipanggil **sekali saja** | Token kosong di UI — backend tidak pernah menerima token sama sekali | Dicoba ulang sampai 6 kali dengan jeda 1 detik | `getToken()` memang bisa mengembalikan `null` pada percobaan pertama karena registrasi FCM belum selesai. Ini **ditemukan saat aplikasi dijalankan**, bukan dari membaca kode |
| 10 | Token tidak reaktif — UI membacanya sekali saat `build()` | Token akhirnya terbit lewat `onTokenRefresh`, tetapi kartu di beranda tetap kosong | `fcmTokenNotifier` (`ValueNotifier`) + `ValueListenableBuilder` | Token yang datang terlambat tidak akan pernah terlihat kalau UI tidak mendengarkan perubahannya. Ini penyebab paling umum keluhan "token FCM saya kosong" |
| 11 | Channel notifikasi baru dibuat saat notifikasi pertama ditampilkan | Pesan FCM pertama jatuh ke channel bawaan Android yang importance-nya rendah, sehingga **banner tidak muncul sebagai heads-up** | `createNotificationChannel()` dipanggil saat aplikasi dijalankan; id channel dipakai bersama oleh banner lokal dan field *Android Notification Channel* di Firebase Console | Importance channel menentukan apakah notifikasi muncul sebagai banner di atas layar. Channel harus sudah ada sebelum pesan pertama datang |

## 4. Verifikasi (AI Verification Checklist)

1. **Apakah background handler berupa fungsi top-level dengan `@pragma('vm:entry-point')`?**
   Ya. `firebaseMessagingBackgroundHandler` adalah fungsi top-level, diberi
   `@pragma('vm:entry-point')`, dan isinya hanya mencatat ringan — **tidak**
   menyentuh `BuildContext`, Riverpod, atau state UI, karena berjalan di isolate
   terpisah.

2. **Apakah `onTokenRefresh` benar-benar mengirim token baru ke backend, bukan hanya dicetak?**
   Ya. `onTokenRefresh` memanggil `onToken` yang **sama** dengan yang dipakai
   `getToken`, dan `onToken` melakukan `POST /devices`. Endpoint itu belum ada di
   codelab, jadi kegagalannya diabaikan sambil dicatat — dan didokumentasikan di
   README. Yang penting: jalurnya nyata, bukan sekadar `print`.

3. **Apakah foreground memakai local notification manual?**
   Ya. `listenForeground()` memanggil `showLocalBanner()` di dalam `onMessage`.
   Di Android, pesan FCM bertipe `notification` **tidak** menampilkan banner
   otomatis saat aplikasi sedang terbuka — tanpa pemanggilan manual, tidak ada
   yang muncul.

4. **Apakah klik dari ketiga state masuk ke rute yang benar?**
   Rancangannya: foreground → payload banner → `onDidReceiveNotificationResponse`
   → `_dispatchDeepLink`; background → `onMessageOpenedApp`; terminated →
   `getInitialMessage` (lalu `handleTerminated` dipanggil setelah router siap).
   Ketiganya bermuara ke fungsi yang sama, `ref.read(routerProvider).go(route)`.
   Bukti empirisnya berupa tabel pengujian tiga state di README — memerlukan
   Firebase aktif.

5. **Apakah token/secret tidak di-hardcode dan tidak di-log penuh?**
   Tidak ada secret yang ditanam di kode: auth-nya mock, `baseUrl` hanya
   placeholder. Semua token yang muncul di log maupun UI sudah melewati
   `TokenStore.mask()`.

## 5. Keputusan akhir dan yang berbeda dari saran AI

- **Menolak "banner otomatis" untuk foreground.** Pesan bertipe `notification`
  hanya tampil otomatis saat aplikasi di background/terminated. Di foreground
  banner harus ditampilkan manual lewat `flutter_local_notifications` — ini
  penyebab paling umum "notifikasi tidak muncul saat aplikasi terbuka".
- **Menambahkan penanda retry pada interceptor 401.** Codelab hanya meminta
  "refresh sekali", tapi implementasi naif bisa berulang.
- **Menambahkan gerbang `firebaseReady`.** Bukan permintaan codelab, tetapi tanpa
  ini project tidak bisa dijalankan sama sekali sebelum Firebase disiapkan —
  dan itu menghambat semua pengerjaan berikutnya.
- **Menolak menaruh logika navigasi di dalam `PushService`.** Navigasi tetap di
  aplikasi (`main.dart`), sedangkan `PushService` hanya **meminta** deep link
  lewat callback `onDeepLinkRequested`. Dengan begitu service tidak perlu tahu
  apa pun soal router, dan bisa diuji tanpa Firebase.

## 6. Keterbatasan yang diketahui

| Keterbatasan | Dampak | Upgrade yang perlu |
| --- | --- | --- |
| Firebase belum dikonfigurasi | Seluruh fitur FCM nonaktif; hanya tombol simulasi banner lokal yang bekerja | Ikuti bagian "Mengaktifkan FCM" di README (butuh `google-services.json`) |
| `POST /devices` mengarah ke `https://example-campus-api.test` | Token tidak benar-benar tersimpan di server | Ganti `baseUrl` di `api_client.dart` dengan API kampus |
| Auth masih mock | Token tidak diverifikasi server | Ganti isi `AuthRepository.login` dengan `FirebaseAuth` + `getIdToken()`; sisa arsitektur tidak perlu berubah |
| Token disimpan tanpa enkripsi tingkat aplikasi tambahan | Mengandalkan Keystore/Keychain platform | Untuk kebutuhan tinggi, tambahkan rotasi token dan binding perangkat |
