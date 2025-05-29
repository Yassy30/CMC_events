class Like {
  final String id;
  final String eventId;
  final String userId;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.createdAt,
  });

  factory Like.fromMap(Map<String, dynamic> data) {
    return Like(
      id: data['id'],
      eventId: data['event_id'],
      userId: data['user_id'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}