# AI Challenge — Minggu 4: Networking & REST API

## Prompt yang Digunakan

```
Buatkan repository layer Flutter untuk endpoint GET
/comments?postId={id} dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

## Output Awal dari AI

AI menghasilkan kode dengan struktur:
- `Comment` model dengan `fromJson` menggunakan cast `as num?` dan `as String?`
- `CommentRepository` dengan method `fetchComments(postId)`
- `AsyncNotifierProvider.family` dengan `build(int postId)`
- Satu unit test untuk happy path `fromJson`

## Perbaikan yang Dilakukan

### 1. fromJson — Tambah `safeToInt()`

Kode AI hanya menangani `int` dan `String`. Ditambah helper `safeToInt()` yang menangani `int`, `double`, `String` berisi angka, dan `null`:

```dart
int safeToInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
```

### 2. Riverpod 3.x Family API

Kode AI menggunakan `build(int postId)` sebagai parameter family. Di Riverpod 3.x, family argument di-pass melalui constructor, bukan `build()`:

```dart
// Sebelum (salah)
class CommentNotifier extends AsyncNotifier<List<Comment>> {
  @override
  Future<List<Comment>> build(int postId) async { ... }
}

// Sesudah (benar)
class CommentNotifier extends AsyncNotifier<List<Comment>> {
  CommentNotifier(this.postId);
  final int postId;
  @override
  Future<List<Comment>> build() async { ... }
}
```

### 3. Test — Tambah Edge Case

Kode AI hanya menguji happy path. Ditambah test untuk field hilang, tipe data bercampur (`String` di field `int`), dan mapping error untuk berbagai `DioExceptionType`. Total 8 test (dari semula 1).

## Alasan Keputusan Teknis

- `safeToInt()` dibuat karena API nyata sering tidak konsisten dalam tipe data
- `autoDispose` digunakan agar state komentar dibuang dari memory saat tidak dipakai
- `retry: (retryCount, error) => null` agar error langsung final dan mudah diuji
