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
