import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/SupabaseConfig.dart';
import '../models/event.dart';

class EventRepository {
  final _client = SupabaseConfig.client;

  Future<String> createEvent(Event event) async {
    try {
      // Log the event data before insertion
      print('Inserting event with data: ${event.toJson()}');
      
      final response = await _client
          .from('events')
          .insert(event.toJson())
          .select('id')
          .single();

      if (response['id'] != null) {
        print('Event created with ID: ${response['id']}');
        return response['id'] as String;
      } else {
        throw Exception('Failed to retrieve event ID after creation');
      }
    } catch (e) {
      print('Error in EventRepository.createEvent: $e');
      rethrow;
    }
  }

  Future<List<Event>> getEvents({String? category}) async {
    try {
      // Start with a simple select
      var query = _client.from('events').select('*, users(username, profile_picture)');
      
      // Apply category filter if provided
      if (category != null && category != 'All Events') {
        query = query.eq('category', category.toLowerCase());
      }
      
      // Apply ordering
      final data = await query.order('created_at', ascending: false);
      
      return (data as List).map<Event>((item) => Event.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching events in repository: $e');
      return [];
    }
  }

  Future<Event?> getEventById(String id) async {
    try {
      final data = await _client
          .from('events')
          .select('*, users(username, profile_picture)')
          .eq('id', id)
          .single();
      
      return Event.fromJson(data);
    } catch (e) {
      print('Error fetching event by id in repository: $e');
      return null;
    }
  }
}