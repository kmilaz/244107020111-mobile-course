# Week 2 — Declarative UI & Responsive Design

Mini assignment Minggu 2: memahami prinsip declarative UI, membangun layout responsif dengan widget dasar Flutter, menerapkan dark/light theme, serta menambahkan label aksesibilitas untuk screen reader.

## 1. Tujuan

Setelah menyelesaikan codelab ini, mahasiswa mampu:

- Menjelaskan prinsip **declarative UI** dan hubungan antara widget, konfigurasi, serta state.
- Menggunakan `StatelessWidget`, `StatefulWidget`, `Container`, `Row`, `Column`, dan `Expanded`.
- Membedakan komponen **Material 3** dan **Cupertino** untuk kebutuhan platform yang berbeda.
- Membangun **layout responsif** untuk ukuran layar mobile dan tablet.
- Menerapkan **theme**, **dark mode**, **styling**, dan **aksesibilitas dasar** (`Semantics`).

## 2. Fitur Utama

Aplikasi Academic Overview (`lib/main.dart`):

### Praktikum — Student Dashboard

- `StatefulWidget` sebagai root (`DashboardApp`) untuk mengelola state `isDark`.
- `MaterialApp` dengan `theme` / `darkTheme` berbasis `ThemeData(useMaterial3: true)`.
- Toggle tema menggunakan `Switch.adaptive` di `AppBar` actions.
- Body `LayoutBuilder` mendeteksi lebar layar → `GridView.count` dengan `crossAxisCount` dinamis:
  - **Layar sempit** (< 600 px) → 1 kolom.
  - **Layar lebar** (≥ 600 px) → 2 kolom.
- Empat `DashboardCard` berisi: Assignments, Attendance, Portfolio, Current Week.
- Setiap kartu menggunakan `Card` → `Padding` → `Row` dengan `Expanded` untuk teks + nilai.

### Tugas — Academic Overview

- Profil header (`_ProfileHeader`): `Container` dengan gradient, `CircleAvatar` inisial, nama, NIM, dan badge semester.
- Empat kartu informasi (`InfoCard`): GPA, Attendance, Assignments, Current Week — masing-masing dengan ikon berwarna dan subtitle.
- Quick Summary Row: `Container` dengan `Row` → `Icon` + `Expanded(Column)` menampilkan ringkasan mata kuliah.
- Layout responsif via `LayoutBuilder` → `SliverGrid` dengan `SliverGridDelegateWithFixedCrossAxisCount`:
  - **Mobile** → 1 kolom, `childAspectRatio: 2.8`.
  - **Tablet** → 2 kolom, `childAspectRatio: 2.4`.
- Seluruh elemen penting dibungkus `Semantics` dengan label deskriptif untuk screen reader.


## 3. Stack Teknologi

| Komponen | Detail |
|---|---|
| Framework | Flutter (Material 3 + Cupertino icons) |
| Bahasa | Dart `^3.13.2`, null safety aktif |
| Dependency | `cupertino_icons ^1.0.8` (pubspec), `flutter_lints ^6.0.0` (dev) |
| Widget kunci | `LayoutBuilder`, `GridView.count`, `Row`, `Column`, `Expanded`, `Container`, `Switch.adaptive`, `Semantics` |
| IDE | VS Code + ekstensi Flutter/Dart |
| Platform target | Android (emulator / perangkat fisik) |
| Version control | Git + GitHub |

## 4. Cara Menjalankan

### Prasyarat

- Flutter SDK (`flutter/bin` masuk `PATH`), Android Studio + Android SDK / emulator.

### Verifikasi environment

```bash
flutter --version
flutter doctor
flutter devices   # minimal 1 target muncul
```

### Jalankan aplikasi

```bash
cd 02-week-2-declarative-ui-responsive-design
flutter pub get
flutter run        # pilih emulator / perangkat bila diminta
```

Di terminal `flutter run`: tekan `r` = hot reload, `R` = hot restart.

## 5. Hasil yang Dicapai
- [x] Membuat kartu profil sederhana
![](screenshots/ss-01.png)

- [x] Eksperimen menghapus `Expanded` pada baris nama
> Sebelum: ![](screenshots/ss-01.png)

> Sesudah: ![](screenshots/ss-02.png)

- [x] Eksperimen Mengganti `mainAxisSize: MainAxisSize.min` menjadi nilai default

![](screenshots/ss-03.png)

- [x] Eksperimen menambahkan satu baris data menggunakan pola `Row` + `Expanded` yang sama

![](screenshots/ss-04.png)

### Praktikum — Dashboard Responsif
- [x] Membuat aplikasi profil sederhana

![](screenshots/ss-05.png)

- [x] Menambahkan interaksi dengan StatefulWidget dan Cupertino

![](screenshots/ss-06.png)

- [x] Perbedaan tampilan CupertinoSwitch dan Switch.adaptive
> CupertinoSwitch ![](screenshots/ss-06.png)

> Switch.adaptive ![](screenshots/ss-07.png)

- [x] Eksperimen mengubah breakpoint dari 700 menjadi 200

![](screenshots/eksperimen-01.png)

- [x] Eksperimen mengubah `themeMode`

![](screenshots/eksperimen-02.png)
![](screenshots/eksperimen-03.png)

- [x] Menguji dengan ukuran layar emulator yang berbeda

![](screenshots/eksperimen-04.png)

- [x] Eksperimen menambahkan `Semantics` atau label untuk screen reader

![](screenshots/eksperimen-05.png)


### Tugas — Academic Overview (Final)

- [x] Header profil dengan avatar, nama, NIM, dan badge semester.
- [x] Empat kartu informasi (GPA, Attendance, Assignments, Current Week) dengan ikon berwarna dan subtitle.
- [x] Layout responsif: 1 kolom (phone) dan 2 kolom (tablet).
- [x] Toggle tema light/dark menggunakan `CupertinoSwitch`.
- [x] Label aksesibilitas (`Semantics`) pada profil, setiap kartu, toggle tema, dan quick summary.

  ![Academic Overview — dark mode, phone](screenshots/tugas-praktikum-1.png)
  ![Academic Overview — light mode, tablet](screenshots/tugas-praktikum-2.png)

### AI Prompt Challenge

Setelah implementasi mandiri selesai, tiga prompt dikirimkan ke AI untuk membandingkan alternatif desain dan memverifikasi hasil:

#### 1. Prompt Perbandingan Tata Letak

> *"Bandingkan dua tata letak dashboard akademik untuk Flutter: versi `GridView` dan versi `LayoutBuilder` + `Column`. Jelaskan trade-off responsif dan aksesibilitasnya."*

**Output:** Menggunakan `LayoutBuilder` + `SliverGrid` (bukan `GridView.count`) karena memberikan kontrol lebih halus terhadap `SliverGridDelegateWithFixedCrossAxisCount` — `childAspectRatio` bisa diatur berbeda untuk mobile (2.8) dan tablet (2.4), sehingga proporsi kartu tetap nyaman dibaca di kedua ukuran layar. `GridView.count` lebih ringkas tetapi kurang fleksibel untuk variasi aspect ratio per breakpoint.

#### 2. Prompt Penguatan Konsep

> *"Jelaskan kapan penggunaan `Expanded` justru menyebabkan overflow di dalam `Row`, beri contoh kode yang gagal dan perbaikannya."*

**Output:** `Expanded` menyebabkan overflow saat digunakan pada konten dengan lebar minimum yang melebihi sisa ruang `Row` — misal teks panjang tanpa `overflow: TextOverflow.ellipsis`. Pada proyek ini, setiap `Row` menggunakan `Expanded` hanya untuk satu elemen teks (sisi lain berisi ikon atau badge dengan lebar tetap), sehingga risiko overflow terminimalkan. Untuk keamanan tambahan, teks panjang pada kartu dibatasi dengan `maxLines` dan `ellipsis`.

#### 3. Verification Prompt

> *"Periksa kembali rekomendasi layout di atas: apakah tetap responsif di bawah 600px, apakah mengurangi aksesibilitas, dan apakah ada widget yang tidak tersedia di Flutter stabil saat ini?"*

**Hasil verifikasi:** Seluruh widget yang digunakan (`LayoutBuilder`, `SliverGrid`, `SliverAppBar`, `Semantics`, `Switch.adaptive`, `CupertinoIcons`) tersedia di Flutter stabil. Breakpoint 600px bekerja dengan benar — di bawah 600px layout menampilkan 1 kolom, di atas menampilkan 2 kolom. Tidak ada penurunan aksesibilitas karena `Semantics` labels tetap aktif di kedua mode layout.

#### Dokumentasi Keputusan

| Aspek | Keputusan | Alasan |
|---|---|---|
| Layout engine | `LayoutBuilder` + `SliverGrid` | Aspect ratio dinamis per breakpoint |
| Toggle tema | `Switch.adaptive` | Tampil native di Material & Cupertino |
| Proyek akhir | Material 3 (`ThemeData`) | Konsisten dengan praktikum & lebih banyak widget |
| Breakpoint | 600 px | Batas umum phone vs tablet Flutter |
| Aksesibilitas | `Semantics` pada semua elemen informatif & interaktif | Wajib untuk screen reader |

### Refactoring Challenge
Memastikan hasil refactoring yang telah dilakukan tidak ada error menggunakan `flutter analyze`
![](screenshots/hasil-refactor.png)

### Testing
Memverifikasi perilaku responsif menggunakan `flutter test`
![](screenshots/hasil-test.png)


## 6. Refleksi

### Apa perbedaan cara berpikir imperative dan declarative saat membangun UI?

> Dalam pendekatan **imperative**, developer mengontrol UI secara langkah demi langkah — misal: `button.setText("Submit")`, lalu `button.setColor(blue)` saat state berubah. Developer harus melacak status UI secara manual. Dalam **declarative** (Flutter), cukup mendeskripsikan "UI harus seperti ini untuk state begini" — Flutter yang menangani rebuild otomatis. Contoh nyata: mengubah `isDark = true` langsung mengubah seluruh palet warna aplikasi tanpa perlu memanggil `setColor()` pada setiap widget. Cara berpikir ini menggeser fokus dari "bagaimana mengubah UI" menjadi "bagaimana UI seharusnya terlihat pada kondisi tertentu".

### Kapan `Expanded` membantu dan kapan penggunaannya justru menghasilkan layout error?

> `Expanded` sangat membantu saat ingin membagi ruang secara proporsional dalam `Row` atau `Column` — misal teks judul mengambil sisa ruang setelah ikon, atau dua kartu berbagi lebar layar secara merata (50:50). Namun, `Expanded` menjadi masalah saat konten di dalamnya memiliki **lebar minimum** yang melebihi sisa ruang yang tersedia — ini memicu **overflow** (yellow/black striped warning). Misal: dua `Expanded` masing-masing berisi `Text` dengan teks sangat panjang tanpa batasan. Solusinya: batasi panjang teks dengan `maxLines` + `overflow: TextOverflow.ellipsis`, atau gunakan `Flexible` (yang bisa mengecil daripada memaksa overflow). Intinya: `Expanded` membantu saat ada ruang untuk dibagi, tetapi error saat konten menuntut lebih dari yang tersedia.

### Bagaimana breakpoint dan theme memengaruhi pengalaman pengguna?

> **Breakpoint** menentukan bagaimana layout beradaptasi dengan ukuran layar. Pada proyek ini, breakpoint 600px memisahkan tampilan phone (1 kolom, kartu vertikal) dari tablet (2 kolom, kartu berdampingan). Tanpa breakpoint, layout mungkin terlalu sempit di tablet atau terlalu renggang di phone. **Theme** (light/dark) memengaruhi kenyamanan visual — dark mode mengurangi kelelahan mata di lingkungan gelap, light mode lebih mudah dibaca di bawah sinar matahari. Keduanya bersama-sama memastikan aplikasi tetap fungsional dan nyaman di berbagai kondisi: layar kecil maupun besar, terang maupun gelap.

### Apa yang Anda verifikasi dari rekomendasi AI setelah tugas inti selesai?

> Tiga hal diverifikasi setelah menerima rekomendasi AI: **(1)** Seluruh widget yang disarankan (`LayoutBuilder`, `SliverGrid`, `Semantics`, `Switch.adaptive`) benar-benar tersedia di Flutter stabil — tidak ada widget experimental atau deprecated. **(2)** Breakpoint 600px berfungsi dengan benar di kedua arah — di bawah 600px menampilkan 1 kolom, di atas menampilkan 2 kolom — diverifikasi dengan mengubah ukuran emulator secara manual. **(3)** Aksesibilitas tidak menurun — `Semantics` labels tetap aktif dan terbaca oleh TalkBack di kedua mode layout. Verifikasi ini penting karena AI kadang merekomendasikan widget yang belum stabil atau asumsi yang tidak sesuai dengan kode nyata.

