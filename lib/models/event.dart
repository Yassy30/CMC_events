class Event {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime date;
  final String location;
  final int maxAttendees;
  final int currentAttendees;
  final String organizerId;
  final bool isFree;
  final String category;
  final String? organizerName;
  final String? organizerImageUrl;
  final bool isFollowing;
  final List<String> likes;
  final List<Comment> comments;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.location,
    required this.maxAttendees,
    required this.currentAttendees,
    required this.organizerId,
    required this.isFree,
    required this.category,
    this.organizerName,
    this.organizerImageUrl,
    this.isFollowing = false,
    this.likes = const [],
    this.comments = const [],
  });
}

class Comment {
  final String id;
  final String userId;
  final String username;
  final String? userImageUrl;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    this.userImageUrl,
    required this.text,
    required this.createdAt,
  });
}