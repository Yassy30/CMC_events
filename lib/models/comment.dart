class Comment {
  final String id;
  final String userId;
  final String username;
  final String? userImageUrl;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    this.userImageUrl,
    required this.text,
    required this.createdAt,
  });
}