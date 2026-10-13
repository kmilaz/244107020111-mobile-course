import '../../domain/entities/post.dart';

/// Representasi data post di JSON. Satu-satunya tempat mapping.
class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.title,
    required super.body,
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};

  /// Parsing defensif: field hilang atau bertipe lain tidak boleh menggagalkan
  /// seluruh daftar.
  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );

  Post toEntity() => Post(id: id, title: title, body: body);
}
