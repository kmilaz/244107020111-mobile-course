import '../../domain/entities/note.dart';

/// Representasi data catatan di SQLite.
///
/// Ini satu-satunya tempat `toMap`/`fromMap` boleh hidup — entity di `domain`
/// tetap murni. Model mewarisi entity supaya bisa langsung dipakai di batas
/// data → domain lewat `toEntity()`.
class NoteModel extends Note {
  const NoteModel({
    super.id,
    required super.title,
    super.body = '',
    required super.updatedAt,
    super.dirty = false,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'updated_at': updatedAt.toIso8601String(),
    'dirty': dirty ? 1 : 0,
  };

  /// Parsing defensif: kolom hilang atau bertipe lain tidak boleh membuat satu
  /// baris jelek menggagalkan pembacaan seluruh daftar.
  factory NoteModel.fromMap(Map<String, Object?> map) {
    return NoteModel(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  /// Dipakai saat menyeberang dari layer data ke domain.
  Note toEntity() => Note(
    id: id,
    title: title,
    body: body,
    updatedAt: updatedAt,
    dirty: dirty,
  );
}
