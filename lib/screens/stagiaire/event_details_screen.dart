import 'package:flutter/material.dart';
import '../../models/event.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(event.title),
              background: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(event.category),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        event.isFree ? 'Gratuit' : 'Payant',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(event.description),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 8),
                      Text(event.location),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people),
                      const SizedBox(width: 8),
                      Text('${event.currentAttendees}/${event.maxAttendees} participants'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: event.currentAttendees < event.maxAttendees
              ? () {
                  // TODO: Implémenter la réservation
                }
              : null,
          child: const Text('Réserver une place'),
        ),
      ),
    );
  }
}