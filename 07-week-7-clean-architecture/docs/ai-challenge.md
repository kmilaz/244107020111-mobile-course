# AI Challenge — Clean Architecture

Praktikum Minggu 7, project `07-week-7-clean-architecture` (refactor dari Minggu 5).

## 1. Prompt yang dipakai

Prompt dari codelab, dengan **satu penyesuaian**: baris deskripsi project diarahkan ke
project yang benar-benar direfactor (Offline Notes, bukan `campus_notify`). Sisanya
sama.

```
Project Flutter saya: Offline Notes (catatan offline-first + daftar posts ber-cache).
Kondisi kini: folder lib/{data, pages, widgets}, repository tercampur dengan
implementasi, entity bercampur dengan mapping, beberapa aturan bisnis ada di widget.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur notes.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

## 2. Ringkasan usulan AI

- Struktur `lib/features/<fitur>/{domain,data,presentation}` + `lib/core/`.
- `domain`: entity, **interface** repository, use case, failure.
- `data`: model (mapping di sini), implementasi repository.
- `presentation`: provider (DI + notifier) dan halaman.
- Wiring DI lewat provider Riverpod, tanpa package DI tambahan.
- Use case dibuat untuk **setiap** operasi: `GetNotes`, `GetNoteById`, `AddNote`,
  `UpdateNote`, `DeleteNote`, `SyncNotes`.

## 3. Verifikasi (AI Verification Checklist)

| # | Pertanyaan | Temuan | Putusan |
| --- | --- | --- | --- |
| 1 | Interface repository di `domain`, implementasi di `data`? | Ya. Interface di `features/notes/domain/repositories/`, impl di `features/notes/data/repositories/`. | ✅ **diterima** |
| 2 | `domain` bebas import Flutter/Dio/SQLite/Firebase? | Ya. Diperiksa dengan grep, **0 hasil** di `features/notes/domain` + `lib/core`. | ✅ **diterima** |
| 3 | Use case untuk tiap CRUD satu-baris? | **Ya — dan itu over-engineering.** AI mengusulkan `GetNotes`, `GetNoteById`, dan `DeleteNote` yang isinya hanya meneruskan panggilan. | ❌ **ditolak sebagian** |
| 4 | Entity bebas mapping (`toMap`/`fromMap` hanya di model)? | AI menaruh `toMap`/`fromMap` di dalam entity supaya "praktis". | ❌ **ditolak** |
| 5 | Wiring DI terpusat di provider, widget tidak `new Repository()`? | Ya untuk provider dan halaman. **Tetapi** ada satu pelanggaran: `main.dart` memanggil `PrefsRepository()` langsung. | ⚠️ **diterima dengan perbaikan** |

### Kenapa #3 ditolak sebagian

Aturan yang dipakai: **use case hanya layak bila ia memegang aturan**, bukan sekadar
meneruskan panggilan.

| Operasi | Isinya | Keputusan |
| --- | --- | --- |
| `AddNote` | menolak judul kosong; wajib `dirty = true` | ✅ use case |
| `UpdateNote` | `updatedAt = now` + `dirty = true` | ✅ use case |
| `SyncNotes` | urutkan antrean; tandai bersih **per baris** | ✅ use case |
| `GetNotes`, `GetNoteById`, `DeleteNote` | meneruskan begitu saja | ❌ repository langsung |

Efeknya bukan hanya lebih ringkas: test jadi menguji **aturan yang nyata**, bukan
menguji bahwa sebuah fungsi meneruskan argumennya.

> Ironi yang layak dicatat: contoh di codelab sendiri memakai `GetNotes` sebagai use
> case tipis — sementara checklist verifikasinya menyebut pola itu over-engineering.
> Codelab tidak konsisten di titik ini, dan keputusan di sini mengikuti checklist-nya.

### Kenapa #4 ditolak

Entity harus bisa dipakai tanpa menyentuh database. Kalau `toMap`/`fromMap` menempel di
entity, maka entity ikut berubah setiap kali bentuk penyimpanan berubah — dan test
domain jadi ikut bergantung pada bentuk map. Solusinya: entity murni di `domain`,
`NoteModel` di `data` (yang juga mewarisi entity supaya perpindahan data → domain
tinggal `toEntity()`).

### #5 — pelanggaran yang ditemukan

```dart
// main.dart, sebelum perbaikan
await PrefsRepository().markOpenedNow();
```

Ini satu-satunya tempat yang membuat repository di luar provider. Sudah dipindahkan:
sekarang dipanggil lewat `prefsRepositoryProvider` dari dalam aplikasi, dan
`lastOpenedProvider` di-invalidate setelahnya.

## 4. Tabel ringkas: usulan AI vs keputusan final

| Hal | Usulan AI | Keputusan final | Alasan |
| --- | --- | --- | --- |
| Struktur folder | `core/` + `features/<fitur>/<layer>` | **diikuti** | sesuai codelab, dan fitur bisa dipahami terpisah |
| Interface repository | di `domain` | **diikuti** | aturan dependency inversion |
| Use case per operasi | semua operasi | **hanya yang beraturan** | hindari lapisan kosong; checklist codelab sendiri menandainya over-engineering |
| Mapping di entity | `toMap`/`fromMap` di entity | **dipisah ke model** | entity harus murni supaya domain bisa diuji tanpa storage |
| DI | Riverpod saja | **diikuti** | tidak perlu package DI tambahan |
| `main.dart` | tidak disebut | **diperbaiki** | DI bocor satu titik |

## 5. Keputusan tambahan yang menyimpang dari contoh codelab

1. **Aturan bisnis di use case, bukan di repository impl.** Contoh codelab membangun
   `NoteModel(dirty: true, updatedAt: now)` di dalam `addNote()` milik impl. Di sini
   `AddNote`/`UpdateNote` yang membentuk entity, dan repository hanya menyimpan apa
   adanya. Repository jadi benar-benar "pintu penyimpanan", dan aturan bisnis ada di
   satu tempat yang bisa diuji tanpa database.
2. **`countDirty` dihapus dari kontrak.** Badge dihitung dari daftar yang sama
   (`notesProvider`) supaya chip dan badge tidak bisa bercerita berbeda — sehingga
   query `COUNT` terpisah menjadi tidak perlu.
3. **Konstruktor impl memakai parameter posisional.** Bentuk *named* dari contoh
   codelab memicu lint `prefer_initializing_formals`, yang membuat `flutter analyze`
   tidak bersih.

## 6. Keterbatasan yang diketahui

| Keterbatasan | Dampak | Upgrade yang perlu |
| --- | --- | --- |
| Fitur `posts` dan preferensi belum berlapis | Sisa `lib/data/` masih menyimpan provider posts + preferensi | Dikerjakan pada Refactoring Challenge |
| `SyncNotes` memakai `Future.delayed` | Tidak ada backend tulis untuk diuji | Ganti dengan request REST + tandai bersih hanya pada 2xx |
| Error domain berupa record `({nilai, Failure?})` | Lebih sederhana daripada `Either`, tetapi tidak punya operasi `map`/`fold` | Bila alur menjadi kompleks, pertimbangkan `fpdart` |
