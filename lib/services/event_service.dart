
import 'package:cmc_ev/repositories/event_repository.dart';
import '../models/event.dart';

class EventService {
  final EventRepository _repository;

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
}