import 'package:flutter/material.dart';
import 'package:cmc_ev/screens/stagiaire/event_details_view.dart';
import 'package:cmc_ev/models/event.dart';

class EventDetailsFullPage extends StatelessWidget {
  final Event event;
  final ScrollController controller;
  const EventDetailsFullPage({super.key, required this.event, required this.controller});
  @override
  Widget build(BuildContext context) {
    return EventDetailsView(event: event, controller: controller);
  }
}