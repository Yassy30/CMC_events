
import 'package:cmc_ev/repositories/event_repository.dart';
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
    final creatorId = _authService.currentUserId;
    print('Creating event with creatorId: $creatorId, authUserId');

    if (creatorId.isEmpty) {
      throw Exception('User must be logged in to create an event');
    }

    final event = Event(
      title: title,
      description: description,
      creatorId: creatorId,
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

    final eventJson = event.toJson();
    print('Event JSON before repository call: $eventJson');

    try {
      return await _repository.createEvent(event);
    } catch (e) {
      print('Error in EventService.createEvent: $e');
      rethrow;
    }
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
      // Get all reservations for this event
      final response = await _client
          .from('reservations')
          .select('payment_status')
          .eq('event_id', eventId);

      print('Found ${response.length} reservations for event $eventId');

      // Count all reservations (both pending and completed)
      // For display purposes we want to show all reserved spots
      return response.length;
    } catch (e) {
      print('Error getting reservations count: $e');
      return 0;
    }
  }

  // Add method to check if user is registered for an event
  Future<bool> isUserRegistered(String eventId, String userId) async {
    try {
      final response = await _client
          .from('reservations')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking if user is registered: $e');
      return false;
    }
  }

  // Add method to register a user for an event
  Future<bool> registerForEvent(String eventId, String userId) async {
    try {
      // Check if user is already registered
      final existingRegistration = await _client
          .from('reservations')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .limit(1);

      if (existingRegistration.isNotEmpty) {
        return false; // User already registered
      }

      // First check if there are spots available
      final event = await _client
          .from('events')
          .select()
          .eq('id', eventId)
          .single();

      final reservations = await getReservationsCount(eventId);

      // Check if the event has a max attendee limit and if it's reached
      if (event['max_attendees'] != null && 
          reservations >= event['max_attendees']) {
        throw Exception('Event is fully booked');
      }

      final bool isPaid = event['payment_type'] == 'paid';

      // Insert the reservation record
      await _client.from('reservations').insert({
        'event_id': eventId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'payment_status': isPaid ? 'pending' : 'completed'
      });

      print('Registered user $userId for event $eventId');
      return true;
    } catch (e) {
      print('Error registering for event: $e');
      throw Exception('Failed to register for event: ${e.toString()}');
    }
  }

  // Optional: Add method to cancel registration
  Future<bool> cancelRegistration(String eventId, String userId) async {
    try {
      await _client
          .from('reservations')
          .delete()
          .match({'event_id': eventId, 'user_id': userId});

      return true;
    } catch (e) {
      print('Error cancelling registration: $e');
      return false;
    }
  }

  // Add method to update payment status
  Future<bool> completePayment(String eventId, String userId) async {
    try {
      // Update the reservation status to completed
      final result = await _client
          .from('reservations')
          .update({'payment_status': 'completed'})
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .eq('payment_status', 'pending');

      print('Payment completed for user $userId on event $eventId');
      return true;
    } catch (e) {
      print('Error completing payment: $e');
      return false;
    }
  }

  // updateEvent({
  //   required String id,
  //   required String title,
  //   required String description,
  //   required DateTime startDate,
  //   required String location,
  //   required String category,
  //   required String paymentType,
  //   double? ticketPrice,
  //   int? maxAttendees,
  //   required String imageUrl,
  //   required bool isCompleted
  // }) {}
    Future<void> updateEvent({
    required String id,
    required String title,
    required String description,
    required DateTime startDate,
    required String location,
    required String category,
    required String paymentType,
    double? ticketPrice,
    int? maxAttendees,
    String? imageUrl, // Changed to optional
    bool? isCompleted, // Changed to optional
  }) async {
    try {
      await SupabaseConfig.client.from('events').update({
        'title': title,
        'description': description,
        'start_date': startDate.toIso8601String(),
        'location': location,
        'category': category,
        'payment_type': paymentType,
        'ticket_price': ticketPrice,
        'max_attendees': maxAttendees,
        'image_url': imageUrl,
        'is_completed': isCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  Future<void> deleteEvent(String id) async {
    if (id.isEmpty) {
      throw Exception('Event ID cannot be empty');
    }
    try {
      final response = await SupabaseConfig.client
          .from('events')
          .delete()
          .eq('id', id)
          .select()
          .maybeSingle();
      if (response == null) {
        throw Exception('Event not found or already deleted');
      }
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  Future<void> completeEvent(String id) async {
    try {
      await _client
          .from('events')
          .update({
            'is_completed': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      print('Event $id marked as completed');
    } catch (e) {
      print('Error completing event: $e');
      throw Exception('Failed to complete event: ${e.toString()}');
    }
  }
}


// import 'package:cmc_ev/repositories/event_repository.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../db/SupabaseConfig.dart';
// import '../models/event.dart';
// import 'auth_service.dart'; // Import AuthService

// class EventService {
//   final EventRepository _repository;
//   final AuthService _authService; // Add AuthService
//   final _client = SupabaseConfig.client;

//   EventService({
//     EventRepository? repository,
//     AuthService? authService, // Add AuthService parameter
//   })  : _repository = repository ?? EventRepository(),
//         _authService = authService ?? AuthService(); // Default to new instance if not provided

// Future<String> createEvent({
//   required String title,
//   required String description,
//   required DateTime startDate,
//   required String location,
//   required String category,
//   required String paymentType,
//   int? maxAttendees,
//   required String imageUrl,
//   double? ticketPrice,
// }) async {
//   final creatorId = _authService.currentUserId;
//   print('Creating event with creatorId: $creatorId, authUserId');

//   if (creatorId.isEmpty) {
//     throw Exception('User must be logged in to create an event');
//   }

//   final event = Event(
//     title: title,
//     description: description,
//     creatorId: creatorId,
//     startDate: startDate,
//     location: location,
//     category: category,
//     paymentType: paymentType,
//     maxAttendees: maxAttendees,
//     imageUrl: imageUrl,
//     ticketPrice: ticketPrice,
//     isCompleted: false,
//     createdAt: DateTime.now(),
//     updatedAt: DateTime.now(),
//   );

//   final eventJson = event.toJson();
//   print('Event JSON before repository call: $eventJson');

//   try {
//     return await _repository.createEvent(event);
//   } catch (e) {
//     print('Error in EventService.createEvent: $e');
//     rethrow;
//   }
// }
//   Future<List<Event>> getEvents({String? category}) async {
//     try {
//       return await _repository.getEvents(category: category);
//     } catch (e) {
//       print('Error fetching events: $e');
//       return [];
//     }
//   }

//   Future<int> getCommentsCount(String eventId) async {
//     try {
//       final response = await _client
//           .from('comments')
//           .select()
//           .eq('event_id', eventId);
//       return response.length;
//     } catch (e) {
//       print('Error getting comments count: $e');
//       return 0;
//     }
//   }

//   Future<int> getReservationsCount(String eventId) async {
//     try {
//       // Get all reservations for this event
//       final response = await _client
//           .from('reservations')
//           .select('payment_status')
//           .eq('event_id', eventId);

//       print('Found ${response.length} reservations for event $eventId');

//       // Count all reservations (both pending and completed)
//       // For display purposes we want to show all reserved spots
//       return response.length;
//     } catch (e) {
//       print('Error getting reservations count: $e');
//       return 0;
//     }
//   }

//   // Add method to check if user is registered for an event
//   Future<bool> isUserRegistered(String eventId, String userId) async {
//     try {
//       final response = await _client
//           .from('reservations')
//           .select()
//           .eq('event_id', eventId)
//           .eq('user_id', userId)
//           .limit(1);

//       return response.isNotEmpty;
//     } catch (e) {
//       print('Error checking if user is registered: $e');
//       return false;
//     }
//   }

//   // Add method to register a user for an event
//   Future<bool> registerForEvent(String eventId, String userId) async {
//     try {
//       // Check if user is already registered
//       final existingRegistration = await _client
//           .from('reservations')
//           .select()
//           .eq('event_id', eventId)
//           .eq('user_id', userId)
//           .limit(1);

//       if (existingRegistration.isNotEmpty) {
//         return false; // User already registered
//       }

//       // First check if there are spots available
//       final event = await _client
//           .from('events')
//           .select()
//           .eq('id', eventId)
//           .single();

//       final reservations = await getReservationsCount(eventId);

//       // Check if the event has a max attendee limit and if it's reached
//       if (event['max_attendees'] != null && 
//           reservations >= event['max_attendees']) {
//         throw Exception('Event is fully booked');
//       }

//       final bool isPaid = event['payment_type'] == 'paid';

//       // Insert the reservation record
//       await _client.from('reservations').insert({
//         'event_id': eventId,
//         'user_id': userId,
//         'created_at': DateTime.now().toIso8601String(),
//         'payment_status': isPaid ? 'pending' : 'completed'
//       });

//       print('Registered user $userId for event $eventId');
//       return true;
//     } catch (e) {
//       print('Error registering for event: $e');
//       throw Exception('Failed to register for event: ${e.toString()}');
//     }
//   }

//   // Optional: Add method to cancel registration
//   Future<bool> cancelRegistration(String eventId, String userId) async {
//     try {
//       await _client
//           .from('reservations')
//           .delete()
//           .match({'event_id': eventId, 'user_id': userId});

//       return true;
//     } catch (e) {
//       print('Error cancelling registration: $e');
//       return false;
//     }
//   }

//   // Add method to update payment status
//   Future<bool> completePayment(String eventId, String userId) async {
//     try {
//       // Update the reservation status to completed
//       final result = await _client
//           .from('reservations')
//           .update({'payment_status': 'completed'})
//           .eq('event_id', eventId)
//           .eq('user_id', userId)
//           .eq('payment_status', 'pending');

//       print('Payment completed for user $userId on event $eventId');
//       return true;
//     } catch (e) {
//       print('Error completing payment: $e');
//       return false;
//     }
//   }

//   updateEvent({required String id, required String title, required String description, required DateTime startDate, required String location, required String category, required String paymentType, double? ticketPrice, int? maxAttendees, required String imageUrl}) {}

//   deleteEvent(String id) {}
// }

