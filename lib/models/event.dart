class Event {
  final String id;
  final String title;
  final String? description;
  final String creatorId;
  final DateTime startDate;
  final String? location;
  final String category;
  final String paymentType;
  final int? maxAttendees;
  final String imageUrl;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    this.id = '',
    required this.title,
    this.description,
    required this.creatorId,
    required this.startDate,
    this.location,
    required this.category,
    required this.paymentType,
    this.maxAttendees,
    required this.imageUrl,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    // creatorId: json['creator_id'],
    creatorId: json['creator_id'],
    startDate: DateTime.parse(json['start_date']),
    location: json['location'],
    category: json['category'],
    paymentType: json['payment_type'],
    maxAttendees: json['max_attendees'],
    imageUrl: json['image_url'],
    isCompleted: json['is_completed'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    // 'id': id,
    'title': title,
    'description': description,
    'creator_id': creatorId,
    'start_date': startDate.toIso8601String(),
    'location': location,
    'category': category,
    'payment_type': paymentType,
    'max_attendees': maxAttendees,
    'image_url': imageUrl,
    'is_completed': isCompleted,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}