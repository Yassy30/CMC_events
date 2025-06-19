import 'dart:convert';

class Event {
  final String id;
  final String title;
  final String? description;
  final String creatorId;
  final String? creatorName;
  final String? creatorImageUrl;
  final DateTime startDate;
  final String? location;
  final String category;
  final String paymentType;
  final int? maxAttendees;
  final String imageUrl;
  final double? ticketPrice;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    String? id,
    required this.title,
    this.description,
    required this.creatorId,
    this.creatorName,
    this.creatorImageUrl,
    required this.startDate,
    this.location,
    required this.category,
    required this.paymentType,
    this.maxAttendees,
    required this.imageUrl,
    this.ticketPrice,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  factory Event.fromJson(Map<String, dynamic> json) {
    final userData = json['users'] as Map<String, dynamic>?;
    
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      creatorId: json['creator_id'],
      creatorName: userData?['username'],
      creatorImageUrl: userData?['profile_picture'],
      startDate: DateTime.parse(json['start_date']),
      location: json['location'],
      category: json['category'],
      paymentType: json['payment_type'],
      maxAttendees: json['max_attendees'],
      imageUrl: json['image_url'],
      ticketPrice: json['ticket_price'] != null ? 
          (json['ticket_price'] is double ? json['ticket_price'] : double.parse(json['ticket_price'].toString())) : null,
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'creator_id': creatorId,
      'start_date': startDate.toIso8601String(),
      'location': location,
      'category': category,
      'payment_type': paymentType,
      'max_attendees': maxAttendees,
      'image_url': imageUrl,
      'ticket_price': ticketPrice,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}