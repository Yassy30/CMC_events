import 'comment.dart';

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
  final int? currentAttendees;
  final String? imageUrl;
  final bool isCompleted;
  final String? organizerName;
  final String? organizerImageUrl;
  final List<Comment>? comments;
  final List<String>? likes;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.creatorId,
    required this.startDate,
    this.location,
    required this.category,
    required this.paymentType,
    this.maxAttendees,
    this.currentAttendees,
    this.imageUrl,
    required this.isCompleted,
    this.organizerName,
    this.organizerImageUrl,
    this.comments,
    this.likes,
  });

  factory Event.fromMap(Map<String, dynamic> data) {
    return Event(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      creatorId: data['creator_id'],
      startDate: DateTime.parse(data['start_date']),
      location: data['location'],
      category: data['category'],
      paymentType: data['payment_type'],
      maxAttendees: data['max_attendees'],
      currentAttendees: data['currentAttendees'],
      imageUrl: data['image_url'],
      isCompleted: data['is_completed'],
      organizerName: data['organizerName'],
      organizerImageUrl: data['organizerImageUrl'],
      comments: data['comments'] != null
          ? (data['comments'] as List).map((c) => Comment.fromMap(c)).toList()
          : null,
      likes: data['likes'] != null ? List<String>.from(data['likes']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
    };
  }
}