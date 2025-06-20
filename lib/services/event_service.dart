import 'package:cmc_ev/repositories/event_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/SupabaseConfig.dart';
import '../models/event.dart';
import 'auth_service.dart'; // Import AuthService

class EventService {
  final EventRepository _repository;
  final AuthService _authService; // Add AuthService
  final _client = SupabaseConfig.client;
 
  EventService({
    EventRepository? repository,
    AuthService? authService, // Add AuthService parameter
  })  : _repository = repository ?? EventRepository(),
        _authService = authService ?? AuthService(); // Default to new instance if not provided

  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required String location,
    required String category,
    required String paymentType,
    int? maxAttendees,
    required String imageUrl,
    double? ticketPrice,
  }) async {
    // Get the current user's ID from AuthService
    final creatorId = _authService.currentUserId;

    // Validate creatorId
    if (creatorId.isEmpty) {
      throw Exception('User must be logged in to create an event');
    }

    final event = Event(
      title: title,
      description: description,
      creatorId: creatorId, // Use dynamic creatorId
      startDate: startDate,
      location: location,
      category: category,
      paymentType: paymentType,
      maxAttendees: maxAttendees,
      imageUrl: imageUrl,
      ticketPrice: ticketPrice,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Log the JSON representation of the event
    final eventJson = event.toJson();
    print('Event JSON before repository call: $eventJson');

    return await _repository.createEvent(event);
  }

  Future<List<Event>> getEvents({String? category}) async {
    try {
      return await _repository.getEvents(category: category);
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  Future<int> getCommentsCount(String eventId) async {
    try {
      final response = await _client
          .from('comments')
          .select()
          .eq('event_id', eventId);
      return response.length;
    } catch (e) {
      print('Error getting comments count: $e');
      return 0;
    }
  }

  Future<int> getReservationsCount(String eventId) async {
    try {
      final response = await _client
          .from('reservations')
          .select()
          .eq('event_id', eventId);
      return response.length;
    } catch (e) {
      print('Error getting reservations count: $e');
      return 0;
    }
  }
}