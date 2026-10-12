# AI Challenge — Pemilihan Local Storage

Praktikum Minggu 5, project `05-week-5-local-storage-offline-first`.

## 1. Prompt yang dipakai

```
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

## 2. Ringkasan jawaban AI

- Preferensi tema → `SharedPreferences`.
- Catatan → **Drift** (SQL, tipe aman saat compile, dan `watch()`).
- Hive dinilai hanya cocok untuk cache objek sederhana: untuk 1000 catatan, urutan
  `updated_at` harus disortir manual di memori setelah seluruh box dibaca.
- Skema Drift yang diusulkan hanya berisi kolom CRUD:
  `id`, `title`, `body`, `updatedAt`, ditambah satu index pada `updated_at`.

## 3. Tabel perbandingan

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
| --- | --- | --- | --- | --- |
| Kompleksitas query | tidak ada query, hanya get/set key bertipe primitif | query manual di memori, tidak ada SQL | SQL penuh: `WHERE`, `ORDER BY`, `JOIN`, agregat | SQL penuh, query diverifikasi compiler |
| Kebutuhan relasi | tidak ada | `HiveList` manual, tanpa foreign key | ada (FK, `JOIN`, transaksi) | ada, relasi dideklarasikan di kode |
| Reaktivitas (stream) | tidak ada | `box.watch()` per key | **tidak ada** — harus membaca ulang sendiri setelah mutasi | `watch()` per query, UI ikut berubah otomatis |
| Type-safety | `dynamic`, cast manual | `TypeAdapter` manual per model | `Map<String, Object?>`, cast manual di `fromMap` | digenerate, error tipe ketahuan saat compile |
| Ukuran boilerplate | paling kecil | perlu adapter + `openBox` | sedang: `CREATE TABLE`, mapping, migrasi manual | paling besar di awal: anotasi tabel, DAO, `build_runner` |
| Kemudahan testing | perlu mock plugin | `Hive.init(tempDir)` | perlu `sqflite_common_ffi`, atau repository palsu | in-memory DB mudah, tapi tetap butuh generated code |

## 4. Skema untuk 1000+ catatan

### 4.1 Skema yang dipakai project ini

`lib/data/local/db.dart`:

```sql
CREATE TABLE notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,      -- ISO-8601: urutan leksikografis = urutan waktu
  dirty INTEGER NOT NULL DEFAULT 0
);
```

Dua keputusan tipe yang disengaja:

- `updated_at` disimpan `TEXT` dalam ISO-8601, karena SQLite tidak punya tipe tanggal
  dan format ISO-8601 membuat `ORDER BY updated_at` sama dengan urutan waktu.
- `dirty` disimpan `INTEGER` 0/1, karena SQLite tidak punya boolean.

### 4.2 Yang perlu ditambahkan untuk 1000+ baris

```sql
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_notes_dirty ON notes(dirty) WHERE dirty = 1;
```

Alasannya: tanpa index, `ORDER BY updated_at DESC` dan `WHERE dirty = 1` memaksa
SQLite memindai seluruh tabel baris demi baris. Index berperan seperti daftar isi,
sehingga baris yang dicari bisa ditemukan tanpa membaca semuanya. Index kedua
sengaja dibuat **partial** (`WHERE dirty = 1`) karena yang dicari hanya baris dirty —
daftar isinya jadi jauh lebih kecil dan lebih cepat.

### 4.3 Kenapa bukan Hive untuk 1000 catatan

Alternatif Hive (satu box, key = id, value = `Map`) tidak bisa memfilter `dirty = 1`
tanpa membaca semua objek, dan urutan `updated_at` tetap harus disortir manual di
memori setelah seluruh box dibaca. Untuk 1000 catatan itu berarti setiap kali daftar
ditampilkan, seluruh koleksi dimuat. Alasan utama SQLite dipilih.

## 5. Verifikasi jawaban AI (AI Verification Checklist)

### 5.1 Apakah AI menaruh daftar catatan di SharedPreferences?

**Temuan:** tidak. AI menaruh preferensi di `SharedPreferences` dan catatan di Drift —
pemisahan yang benar.

**Putusan: diterima.** Kalau AI menyarankan menyimpan koleksi di `SharedPreferences`,
usulan itu akan ditolak dengan alasan: nilai di sana adalah satu blob opak, sehingga
mengubah satu catatan menulis ulang seluruh koleksi; tidak ada `ORDER BY`, tidak ada
update parsial, dan `dirty = 1` tidak bisa difilter tanpa membaca semuanya.

### 5.2 Apakah skema AI mendukung antrean sync (`dirty` / `updated_at`)?

**Temuan:** **tidak lengkap.** Skema AI punya `updatedAt` (cukup untuk mengurutkan
daftar dan untuk aturan konflik *last-write-wins*), tetapi **tidak punya penanda
antrean** seperti `dirty`, maupun tabel `outbox`. Yang diusulkan hanya CRUD polos.

Penyebabnya bisa ditelusuri: **prompt-nya sendiri tidak menyebut offline-first.**
Prompt hanya meminta "CRUD catatan + preferensi tema", jadi AI tidak punya dasar untuk
menambahkan kolom antrean sync.

**Putusan: skema AI ditolak sebagai tidak lengkap.** Kolom `dirty INTEGER NOT NULL
DEFAULT 0` ditambahkan, dan mekanisme antreannya dibangun sendiri (`syncNotes` +
penandaan bersih setelah respons sukses).

**Pelajaran:** kualitas jawaban AI dibatasi oleh kelengkapan prompt. Kebutuhan yang
tidak ditulis di prompt tidak akan muncul di jawaban — termasuk kebutuhan yang justru
inti dari aplikasinya.

### 5.3 Apakah klaim "real-time" didukung stream?

**Temuan:** **ya, didukung.** Jawaban AI menyebut `watch()` secara eksplisit untuk
Drift dan `box.watch()` untuk Hive, bukan sekadar mengklaim "real-time".

Sebagai pembanding, klaim yang sama untuk sqflite tidak akan sah: sqflite tidak punya
API stream, jadi UI harus di-refresh manual setelah setiap mutasi.

**Putusan: diterima sebagai fakta.** Namun reaktivitas itu **tidak dipakai** di project
ini — alasannya di bagian 7.

### 5.4 Apakah estimasi boilerplate AI masuk akal?

Estimasi AI bersifat kualitatif ("paling besar di awal"), tanpa angka. Jadi saya
mengukurnya secara empiris, bukan memperkirakannya.

**Cara uji:** project Flutter kosong terpisah, lalu satu tabel + satu DAO minimal
(29 baris), kemudian menjalankan codegen.

```bash
flutter create --platforms=android --project-name drift_probe drift_probe
flutter pub add drift drift_flutter dev:build_runner dev:drift_dev
dart run build_runner build --delete-conflicting-outputs
```

Versi yang terpasang: `drift 2.35.2`, `drift_dev 2.35.1`, `drift_flutter 0.3.1`,
`build_runner 2.16.2`.

| Yang diukur | Hasil |
| --- | --- |
| Paket baru yang masuk ke `pubspec.lock` | **66** |
| Baris yang saya tulis sendiri (`lib/database.dart`) | **29** |
| Baris yang digenerate (`lib/database.g.dart`) | **487** |
| Langkah wajib sebelum satu query pun bisa dipakai | **1** (`dart run build_runner build`) |
| Waktu codegen | **~87 detik**; pada run pertama ~152 detik (65 detik di antaranya kompilasi builder) |

**Putusan: estimasi AI diterima, tetapi angkanya jauh lebih besar daripada yang mudah
dibayangkan dari kalimat "paling besar di awal".** Rasio 29 baris ditulis → 487 baris
digenerate, ditambah satu langkah codegen yang harus diulang setiap kali skema berubah.

## 6. Keputusan final

| Kebutuhan | Pilihan | Alasan |
| --- | --- | --- |
| Preferensi tema + waktu terakhir dibuka | `SharedPreferences` | key-value kecil, tanpa query dan relasi; setup paling murah |
| Catatan + antrean sync | `sqflite` (SQLite) | butuh `ORDER BY updated_at DESC`, filter `dirty = 1`, dan update baris tunggal |
| Data bacaan (posts) | `sqflite` (`cached_posts`) + Dio | satu engine dan satu file database untuk dua kebutuhan, tanpa storage tambahan |

## 7. Yang saya tolak dari rekomendasi AI

**Saya menolak Drift untuk catatan, dan memakai sqflite.**

Alasan teknisnya:

1. Project ini hanya punya **satu tabel** dan **satu antrean sederhana**. Kekuatan
   Drift — query kompleks dan relasi — tidak terpakai.
2. Boilerplate-nya terukur dan berat: **487 baris digenerate** untuk 29 baris yang
   ditulis, ditambah **satu langkah codegen wajib** setiap skema berubah. Untuk satu
   tabel, itu biaya yang tidak menghasilkan manfaat.
3. Reaktivitas `watch()` memang nyata, tetapi **belum dibutuhkan**: aplikasi ini
   single-isolate, dan daftar catatan sudah di-refresh eksplisit setelah setiap mutasi
   melalui satu pemilik daftar (`NotesNotifier.reload()`/`invalidateSelf()`).

**Konsekuensi yang saya terima secara sadar:** karena tidak ada `watch()`, kelas bug
"data di database berubah tetapi UI tidak ikut berubah" **mungkin terjadi**. Tanpa
disiplin, `syncNotes` bisa membersihkan `dirty` di database sementara baris di layar
masih menampilkan "belum tersinkron". Itu sebabnya semua mutasi dirutekan melalui
**satu pemilik daftar** (`NotesNotifier`), dan setiap mutasi diakhiri pembacaan ulang
(`ref.invalidateSelf()`). Dengan Drift, kelas bug ini hilang karena `watch()`
mengabarkan perubahan tabel.

## 8. Keterbatasan yang diketahui (dan pemicu upgrade)

| Keterbatasan | Dampak | Upgrade yang perlu |
| --- | --- | --- |
| Deteksi koneksi nyata tidak ada | `syncNotes` mensimulasikan upload (`Future.delayed`), jadi tetap "berhasil" saat perangkat offline. Yang menahan antrean hanya toggle `forceOffline`. | `connectivity_plus`, atau request nyata sebagai penentu |
| Sync hanya manual (tombol) | Tidak otomatis berjalan saat koneksi kembali | `connectivity_plus` + pemicu otomatis |
| "Server" hanya simulasi | Tidak ada validasi server maupun konflik sungguhan | REST API tulis + `If-Unmodified-Since` atau versi baris |

Keenam paket alternatif di atas **tidak dipasang** di project ini; dicatat sebagai
batas, bukan sebagai pekerjaan yang tertunda tanpa alasan.
