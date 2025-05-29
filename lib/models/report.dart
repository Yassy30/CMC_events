class Report {
  final String id;
  final String eventId;
  final String userId;
  final String reason;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.reason,
    required this.createdAt,
  });

  factory Report.fromMap(Map<String, dynamic> data) {
    return Report(
      id: data['id'],
      eventId: data['event_id'],
      userId: data['user_id'],
      reason: data['reason'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}