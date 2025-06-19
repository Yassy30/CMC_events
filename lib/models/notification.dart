class Notification {
  final String id;
  final String userId;
  final String type;
  final String? eventId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    this.eventId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromMap(Map<String, dynamic> data) {
    return Notification(
      id: data['id'],
      userId: data['user_id'],
      type: data['type'],
      eventId: data['event_id'],
      message: data['message'],
      isRead: data['is_read'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'event_id': eventId,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}