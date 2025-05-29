class SavedEvent {
  final String id;
  final String userId;
  final String eventId;
  final DateTime createdAt;

  SavedEvent({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.createdAt,
  });

  factory SavedEvent.fromMap(Map<String, dynamic> data) {
    return SavedEvent(
      id: data['id'],
      userId: data['user_id'],
      eventId: data['event_id'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}