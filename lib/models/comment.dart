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

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      eventId: map['event_id'],
      userId: map['user_id'],
      text: map['content'] ?? map['text'],
      createdAt: DateTime.parse(map['created_at']),
      username: map['username'],
      userImageUrl: map['profile_picture'] ?? map['user_image_url'],
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