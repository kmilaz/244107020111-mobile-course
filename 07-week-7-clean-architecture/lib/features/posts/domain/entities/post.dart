/// Entity bisnis murni untuk postingan yang dibaca dari API.
///
/// Tanpa `fromJson`/`toJson` — mapping hidup di `data/models/post_model.dart`.
class Post {
  const Post({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;
}
