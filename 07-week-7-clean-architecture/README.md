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
