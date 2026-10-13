/// Fungsi format murni — tanpa import Flutter, sehingga bisa diuji tanpa widget.
///
/// Sebelumnya aturan tampilan tanggal disalin di tiga tempat: halaman pengaturan,
/// label cache posts, dan baris catatan. Sekarang satu sumber saja.
library;

String _two(int value) => value.toString().padLeft(2, '0');

/// `12/10 13:31` — untuk baris catatan.
String formatShortDateTime(DateTime time) =>
    '${time.day}/${time.month} ${time.hour}:${_two(time.minute)}';

/// Stempel untuk label "dari cache ..." (sengaja diawali spasi).
String formatCacheStamp(DateTime time) => ' ${formatShortDateTime(time)}';

/// `12/10/2026 13:31` — untuk halaman pengaturan.
String formatFullDateTime(DateTime time) =>
    '${time.day}/${time.month}/${time.year} ${time.hour}:${_two(time.minute)}';

/// Mengubah stempel ISO-8601 dari penyimpanan menjadi teks siap tampil.
///
/// `null` dan data rusak ditangani sebagai keadaan yang sah, bukan error.
String formatStoredTimestamp(String? raw) {
  if (raw == null) return 'belum tercatat';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw; // data rusak → tampilkan apa adanya
  return formatFullDateTime(parsed);
}
