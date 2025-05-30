import 'package:cmc_ev/repositories/event_repository.dart';
import '../models/event.dart';

class EventService {
  final EventRepository _repository;

  EventService({EventRepository? repository})
      : _repository = repository ?? EventRepository();

  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required String location,
    required String category,
    required String paymentType,
    int? maxAttendees,
    required String imageUrl,
  }) async {
    const creatorId = "26bd4d62-1804-4962-a6b8-d42fffda6475";

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
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final eventJson = event.toJson();
    print('Event JSON before repository call: $eventJson');

    return await _repository.createEvent(event);
  }
}