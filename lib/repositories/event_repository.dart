import 'package:supabase_flutter/supabase_flutter.dart';
import '../../db/SupabaseConfig.dart';
import '../models/event.dart';

class EventRepository {
  Future<String> createEvent(Event event) async {
    try {
      // Log the event data before insertion
      print('Inserting event with data: ${event.toJson()}');

      final response = await SupabaseConfig.client
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
}