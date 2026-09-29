/// Model data untuk komentar dari JSONPlaceholder API.
///
/// Endpoint: GET /comments?postId={postId}
/// Setiap komentar terkait dengan satu postingan (postId)
/// dan berisi informasi pengirim (name, email) serta isi komentar (body).
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  /// ID postingan yang menjadi induk komentar ini.
  final int postId;

  /// ID unik komentar.
  final int id;

  /// Judul/ringkasan komentar.
  final String name;

  /// Email pengirim komentar.
  final String email;

  /// Isi teks lengkap komentar.
  final String body;

  /// Factory constructor: mengubah JSON mentah menjadi objek Comment.
  ///
  /// Menggunakan cast defensif agar tidak crash jika server
  /// mengembalikan field dengan tipe berbeda atau null.
  ///
  /// Pola `num?` menangani int DAN double dari JSON.
  /// Pola `toString()` + `int.tryParse` menangani kasus ekstrem
  /// di mana API mengembalikan angka sebagai string (misal "2").
  /// Default value (0 atau '') dipakai sebagai fallback terakhir.
  factory Comment.fromJson(Map<String, dynamic> json) {
    // Helper: konversi ke int dengan aman dari berbagai tipe
    int safeToInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt(); // int atau double
      // Jika string berisi angka ("2"), coba parse
      return int.tryParse(value.toString()) ?? 0;
    }

    return Comment(
      postId: safeToInt(json['postId']),
      id: safeToInt(json['id']),
      // String? karena API mungkin return null → default ''
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Mengubah objek Comment kembali menjadi Map (JSON).
  /// Berguna untuk debugging atau jika suatu saat perlu mengirim data ke API.
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
