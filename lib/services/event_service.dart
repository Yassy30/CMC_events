import 'package:cmc_ev/repositories/event_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/SupabaseConfig.dart';
import '../models/event.dart';

class EventService {
  final EventRepository _repository;
  final _client = SupabaseConfig.client;

  EventService({EventRepository? repository})
      : _repository = repository ?? EventRepository();

  Future<String> createEvent({
    required String title,
    required String description,
    required String creatorId,
    required DateTime startDate,
    required String location,
    required String category,
    required String paymentType,
    int? maxAttendees,
    required String imageUrl,
    double? ticketPrice,
  }) async {
    // Validate creatorId
    if (creatorId.isEmpty) {
      throw Exception('creatorId cannot be empty in EventService');
    }

    final event = Event(
      title: title,
      description: description,
      creatorId: "88fc2b88-b79f-4955-ba03-315de8fc5ed2",
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
      // Use simple select and count the response length
      final response = await _client
          .from('comments')
          .select()
          .eq('event_id', eventId);
      
      // Count manually
      return response.length;
    } catch (e) {
      print('Error getting comments count: $e');
      return 0;
    }
  }

  Future<int> getReservationsCount(String eventId) async {
    try {
      // Use simple select and count the response length
      final response = await _client
          .from('reservations')
          .select()
          .eq('event_id', eventId);
      
      // Count manually
      return response.length;
    } catch (e) {
      print('Error getting reservations count: $e');
      return 0;
    }
  }
}