import 'package:flutter/material.dart';
import 'dart:async';
import '../models/event.dart';
import '../repositories/event_repository.dart';

class DiscoverViewModel extends ChangeNotifier {
  final EventRepository _repository;
  final TextEditingController searchController = TextEditingController();
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  List<Event> get events => _filteredEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DiscoverViewModel({EventRepository? repository})
      : _repository = repository ?? EventRepository() {
    fetchEvents();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchEvents({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _repository.getEvents(category: category);
      _filteredEvents = List.from(_events);
      print('Fetched ${_events.length} events, Filtered: ${_filteredEvents.length}');
    } catch (e) {
      _error = 'Failed to load events: $e';
      _filteredEvents = [];
      print('Fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchEvents(String query) async {
    print('Search query: $query');
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        _filteredEvents = List.from(_events);
        _isLoading = false;
        _error = null;
        print('Reset to ${_filteredEvents.length} events');
        notifyListeners();
        return;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        _filteredEvents = await _repository.searchEvents(query.trim());
        print('Search returned ${_filteredEvents.length} events');
      } catch (e) {
        _error = 'Failed to search events: $e';
        _filteredEvents = [];
        print('Search error: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    print('Clearing search');
    searchController.clear();
    _debounce?.cancel();
    _filteredEvents = List.from(_events);
    _isLoading = false;
    _error = null;
    notifyListeners();
    print('Restored ${_filteredEvents.length} events after clear');
  }
}