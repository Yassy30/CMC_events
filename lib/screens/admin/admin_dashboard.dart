import 'package:cmc_ev/db/SupabaseConfig.dart';
import 'package:cmc_ev/models/event.dart';
import 'package:cmc_ev/services/event_service.dart';
import 'package:flutter/material.dart';
import '../../services/report_service.dart';
import '../../models/report.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panneau d\'administration'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Événements'),
              Tab(text: 'Réclamations'),
              Tab(text: 'Statistiques'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EventsTab(),
            _ComplaintsTab(),
            _StatisticsTab(),
          ],
        ),
      ),
    );
  }
}

class _EventsTab extends StatefulWidget {
  @override
  _EventsTabState createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  final EventService _eventService = EventService();
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _eventService.getEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return ListTile(
          title: Text(event.title),
          subtitle: Text('Organisateur: ${event.creatorName ?? "Inconnu"}'),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer'),
              ),
              const PopupMenuItem(
                value: 'warn',
                child: Text('Avertir'),
              ),
            ],
            onSelected: (value) {
              // TODO: Implémenter les actions
            },
          ),
        );
      },
    );
  }
}

class _ComplaintsTab extends StatefulWidget {
  @override
  _ComplaintsTabState createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<_ComplaintsTab> {
  bool _isLoading = false;
  final List<Map<String, String>> _mockReports = [
    {
      'id': '1',
      'reason': 'Contenu inapproprié dans la description de l\'événement',
    },
    {
      'id': '2',
      'reason': 'L\'événement ne correspond pas à la catégorie indiquée',
    },
    {
      'id': '3',
      'reason': 'Informations trompeuses sur le lieu de l\'événement',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _mockReports.length,
      itemBuilder: (context, index) {
        final report = _mockReports[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réclamation #${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(report['reason']!),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('Ignorer'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Traiter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatisticsTab extends StatefulWidget {
  @override
  _StatisticsTabState createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<_StatisticsTab> {
  final _client = SupabaseConfig.client;
  bool _isLoading = true;
  Map<String, int> _stats = {
    'events': 0,
    'users': 0,
    'reservations': 0,
    'reports': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final events = await _client.from('events').count();
      final users = await _client.from('users').count();
      final reservations = await _client.from('reservations').count();
      final reports = await _client.from('reports').count();

      if (mounted) {
        setState(() {
          _stats = {
            'events': events,
            'users': users,
            'reservations': reservations,
            'reports': reports,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      children: [
        _StatCard(
          title: 'Événements',
          value: _stats['events'].toString(),
          icon: Icons.event,
        ),
        _StatCard(
          title: 'Utilisateurs',
          value: _stats['users'].toString(),
          icon: Icons.people,
        ),
        _StatCard(
          title: 'Réservations',
          value: _stats['reservations'].toString(),
          icon: Icons.confirmation_number,
        ),
        _StatCard(
          title: 'Réclamations',
          value: _stats['reports'].toString(),
          icon: Icons.warning,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}