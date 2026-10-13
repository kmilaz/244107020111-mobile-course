# Minggu 7 — Clean Architecture

### Tujuan

Merefactor aplikasi **Offline Notes** (project Minggu 5) menjadi **feature-first Clean Architecture**: memisahkan `presentation`, `domain`, dan `data` pada satu fitur penuh, dengan aturan dependensi **hanya mengarah ke dalam**. Tujuannya agar logika bisnis bisa diuji tanpa database, jaringan, maupun perangkat.

Refactor dikerjakan di folder ini, bukan di folder Minggu 5 — folder asal dibiarkan utuh sebagai pembanding *before/after*.

---

### Peta File ke Layer (kondisi sebelum refactor)

| File | Layer saat ini | Masalah |
| --- | --- | --- |
| `lib/main.dart` | presentation / bootstrap | memakai `PrefsRepository()` langsung — DI bocor |
| `lib/router.dart` | presentation | tidak ada masalah |
| `lib/pages/notes_page.dart` | presentation | memformat tanggal di `_postsLabel()` |
| `lib/pages/note_detail_page.dart` | presentation | membuat `Note(...)` lengkap dengan aturan `dirty: true` dan `updatedAt: now` — aturan bisnis ada di widget |
| `lib/pages/settings_page.dart` | presentation | parsing + memformat tanggal di halaman |
| `lib/widgets/note_tile.dart` | presentation | memformat tanggal (`_formatTime`) |
| `lib/data/local/note.dart` | **domain + data tercampur** | entity sekaligus model: `toMap`/`fromMap` menempel di entity |
| `lib/data/models/post.dart` | **domain + data tercampur** | `Post` sekaligus entity dan model (`toJson`/`fromJson`) |
| `lib/data/repositories/note_repository.dart` | data | **implementasi tanpa interface** → domain tidak punya kontrak (melanggar *Dependency Inversion*) |
| `lib/data/repositories/post_repository.dart` | data | sama: implementasi tanpa interface |
| `lib/data/sync.dart` | **domain di dalam data** | `syncNotes()` memegang aturan bisnis (urutan antrean, penandaan per baris); `PostsCache` memang milik data |
| `lib/data/providers.dart` | **presentation di dalam data** | DI dan seluruh notifier ditaruh di folder `data/` |
| `lib/data/local/db.dart` | data | tidak ada masalah |
| `lib/data/prefs.dart` | data | tidak ada masalah (belum punya kontrak interface) |
| `lib/data/api_client.dart` | data | tidak ada masalah |

**Ringkasan masalahnya:** tidak ada layer `domain` sama sekali. Interface repository tidak ada, entity bercampur dengan mapping, aturan bisnis menyelinap ke widget, dan state presentasi tinggal di folder data.

---

### Pelanggaran yang Ditemukan

Tiga pemeriksaan dari codelab, dijalankan pada `lib/pages`, `lib/widgets`, `lib/main.dart`, dan `lib/data/providers.dart`:

| # | Pemeriksaan | Hasil |
| --- | --- | --- |
| 1 | Presentation menyentuh platform langsung (`Dio(`, `openDatabase`, `SharedPreferences.getInstance`, `jsonDecode`) | **0 hasil** ✓ |
| 2 | Logika/pemformatan di presentation (`tryParse`, `padLeft`, `.day`, `.hour`, `.minute`) | 3 file |
| 3 | Instansiasi manual (`Repository(`, `PostsCache(`) | 1 pelanggaran |

**Temuan 1 — presentation sudah bersih dari platform.** Tidak ada widget yang memanggil Dio, SQLite, atau SharedPreferences langsung. Repository + provider dari Minggu 5 sudah menjaga batas ini. Tidak perlu tindakan.

**Temuan 2 — pemformatan tanggal menempel di presentation.** `settings_page.dart` (`tryParse` + susun `dd/mm/yyyy`), `notes_page.dart` (stempel waktu label "dari cache 12/10 13:31"), dan `note_tile.dart` (`_formatTime`). Aturan tampilan tanggal disalin tiga kali, padahal seharusnya jadi fungsi murni yang bisa diuji tanpa widget → **pindahkan ke `lib/core/format.dart`**.

**Temuan 3 — DI bocor di `main.dart`:**

```dart
await PrefsRepository().markOpenedNow();
```

Bootstrap membuat repository sendiri, bukan menerimanya dari provider. *Catatan jujur:* baris ini berjalan sebelum `ProviderScope` ada, jadi tidak ada container untuk membacanya — tapi tetap pelanggaran, karena tidak ada kontrak yang bisa dipalsukan saat test → **jalankan lewat provider setelah container tersedia**.

`lib/data/providers.dart` **tidak** dihitung sebagai pelanggaran: di situlah DI memang seharusnya. Masalahnya hanya lokasi folder — isinya state presentasi, tapi tinggal di `data/`.

---

### Struktur Target

```
lib/
├── core/                    # murni Dart — tanpa Flutter, Dio, sqflite
│   ├── failures.dart        # Failure: LocalFailure, NetworkFailure
│   └── format.dart          # fungsi murni: format tanggal & stempel waktu
├── data/
│   └── local/db.dart        # infrastruktur bersama: satu file database,
│                            # dipakai tabel `notes` dan `cached_posts`
├── shared/
│   └── providers.dart       # flag demo lintas fitur: force offline
├── features/
│   ├── notes/
│   │   ├── domain/          # entity · interface repository · 3 use case
│   │   ├── data/            # model (mapping) · impl SQLite
│   │   └── presentation/    # providers (DI + notifier) · pages · widgets
│   ├── posts/
│   │   ├── domain/          # entity · 2 interface · use case cache-first
│   │   ├── data/            # model · impl Dio · impl cache SQLite
│   │   └── presentation/    # providers · widget daftar posts
│   └── preferences/
│       ├── domain/          # interface repository preferensi
│       ├── data/            # impl SharedPreferences
│       └── presentation/    # providers · halaman pengaturan
├── main.dart
└── router.dart
```

**Arah dependensi:**

```
presentation  ──>  domain  <──  data
```

`domain` tidak mengimpor Flutter, Dio, sqflite, maupun shared_preferences — itu yang membuatnya bisa diuji tanpa perangkat. Fitur berkomunikasi lewat rute, bukan dengan saling mengimpor halaman.

### Use Case: mana yang layak, mana yang tidak

Codelab memperingatkan **over-engineering**: *"Apakah AI membuat use case untuk tiap CRUD satu-baris? Itu over-engineering — cukup repository langsung ke notifier, dengan alasan tertulis."* Jadi aturannya:

| Operasi | Bentuk | Alasan |
| --- | --- | --- |
| `AddNote` | **use case** | aturan: catatan baru **wajib** bertanda `dirty` |
| `UpdateNote` | **use case** | aturan: set `updatedAt = now` **dan** `dirty` |
| `SyncNotes` | **use case** | aturan: urutkan antrean terlama dulu, tandai bersih **per baris** |
| `LoadPostsCacheFirst` | **use case** | kebijakan: cache dulu → refresh di belakang → timpa cache |
| `DeleteNote`, `GetNotes`, `GetNoteById` | **repository langsung** | tanpa aturan tambahan; use case hanya jadi lapisan kosong |

> Catatan: contoh di codelab memakai `GetNotes` sebagai use case — itu tipis (satu baris meneruskan panggilan). Di sini sengaja tidak dibuat, dan alasannya dicatat. Efeknya: test menguji **aturan yang nyata** (`AddNote`, `SyncNotes`), bukan sekadar penerusan.

---

### Refactor yang Dikerjakan

| Dari | Ke |
| --- | --- |
| `data/local/note.dart` (entity + mapping) | `features/notes/domain/entities/note.dart` (murni) + `features/notes/data/models/note_model.dart` (mapping saja) |
| `data/repositories/note_repository.dart` (implementasi konkret) | `features/notes/domain/repositories/note_repository.dart` (**interface**) + `features/notes/data/repositories/note_repository_impl.dart` (SQLite) |
| `data/sync.dart` → `syncNotes()` | `features/notes/domain/usecases/sync_notes.dart` (aturan antrean jadi milik domain) |
| `data/providers.dart` → provider catatan | `features/notes/presentation/providers/notes_providers.dart` (DI + notifier) |
| `pages/notes_page.dart`, `pages/note_detail_page.dart` | `features/notes/presentation/pages/` |
| `widgets/note_tile.dart` | `features/notes/presentation/widgets/` |
| formatting tanggal di 3 tempat | `core/format.dart` (fungsi murni) |
| `PrefsRepository()` di `main()` | dipanggil lewat provider (DI tidak lagi bocor) |
| `data/models/post.dart` (entity + mapping) | `features/posts/domain/entities/post.dart` (murni) + `features/posts/data/models/post_model.dart` |
| `data/repositories/post_repository.dart` + `PostsCache` di `data/sync.dart` | `features/posts/domain/repositories/` (**2 interface**) + `features/posts/data/repositories/` (`PostRepositoryImpl` Dio, `PostsCacheImpl` SQLite) |
| `data/api_client.dart` | `features/posts/data/api_client.dart` |
| `data/providers.dart` → provider posts | `features/posts/presentation/providers/posts_providers.dart`, dan UI-nya dikeluarkan dari halaman catatan menjadi `features/posts/presentation/widgets/posts_section.dart` |
| `data/prefs.dart` + provider tema | `features/preferences/{domain,data,presentation}` (interface + impl SharedPreferences + provider) |
| `pages/settings_page.dart` | `features/preferences/presentation/pages/settings_page.dart` |
| flag `forceOffline` di `data/providers.dart` | `shared/providers.dart` — dipakai **dua** fitur (refresh posts dan antrean sync), jadi bukan milik salah satunya |

Setelah refactor, `lib/data/` hanya menyisakan **satu** berkas: `local/db.dart` (infrastruktur bersama, karena satu file database dipakai dua fitur).

Aturan bisnis yang tadinya tersebar di widget dan repository sekarang berkumpul di use case: `AddNote` (menolak judul kosong, wajib `dirty`), `UpdateNote` (`updatedAt = now` + `dirty`), `SyncNotes` (urut antrean, tandai bersih per baris).

---

### Verifikasi Aturan Dependensi

Tiga pemeriksaan dari codelab, dijalankan setelah refactor:

| # | Pemeriksaan | Hasil |
| --- | --- | --- |
| 1 | Presentation steril dari data mentah (`Dio(`, `openDatabase`, `getDatabasesPath`, `SharedPreferences.getInstance`, `jsonDecode`) di `features/notes/presentation` + `lib/pages` | **0 hasil** ✓ |
| 2 | Domain steril dari framework (`import 'package:flutter\|dio\|sqflite\|firebase\|shared_preferences`) di `features/notes/domain` + `lib/core` | **0 hasil** ✓ |
| 3 | `flutter analyze` · `flutter test` | **0 issues** · **6 test lulus** ✓ |

Satu baris memang muncul bila pencarian #1 diperluas dengan pola `RepositoryImpl(`:

```dart
// features/notes/presentation/providers/notes_providers.dart
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(openNotesDb),
);
```

Itu **bukan pelanggaran**: berkas ini adalah *composition root* — satu-satunya tempat implementasi konkret dipasang, dan hanya di situ `openNotesDb` boleh diserahkan. Codelab pun menaruh wiring provider di folder presentation.
