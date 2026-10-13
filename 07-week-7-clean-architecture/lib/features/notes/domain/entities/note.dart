/// Entity bisnis murni.
///
/// Tanpa `toMap`/`fromMap`/`toJson`, dan tanpa import apa pun — mapping data
/// hidup di `data/models/note_model.dart`. Ini yang membuat entity bisa
/// dipakai di test tanpa database.
class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;

  /// `true` bila perubahan lokal ini belum pernah diterima server.
  final bool dirty;
}
