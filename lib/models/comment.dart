class Comment {
  final String id;
  final String eventId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String username;
  final String? userImageUrl;

  Comment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.username,
    this.userImageUrl,
  });

  factory Comment.fromMap(Map<String, dynamic> data) {
    return Comment(
      id: data['id'],
      eventId: data['event_id'],
      userId: data['user_id'],
      text: data['content'],
      createdAt: DateTime.parse(data['created_at']),
      username: data['username'] ?? 'Unknown',
      userImageUrl: data['profile_picture'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'content': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}