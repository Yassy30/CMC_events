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
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      userId: map['user_id'] as String,
      text: map['content'] as String? ?? map['text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      username: map['username'] as String? ?? 'Unknown',
      userImageUrl: map['profile_picture'] as String? ?? map['user_image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'content': text,
      'created_at': createdAt.toIso8601String(),
      'username': username,
      'profile_picture': userImageUrl,
    };
  }
}