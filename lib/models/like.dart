class Like {
  final String? id;
  final String eventId;
  final String userId;
  final DateTime createdAt;

  Like({
    this.id,
    required this.eventId,
    required this.userId,
    required this.createdAt,
  });

  factory Like.fromMap(Map<String, dynamic> map) {
    return Like(
      id: map['id'],
      eventId: map['event_id'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'event_id': eventId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}