import 'package:flutter/material.dart';

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

class _EventsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Événement ${index + 1}'),
          subtitle: const Text('Organisateur: John Doe'),
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

class _ComplaintsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
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
                const Text('Description de la réclamation...'),
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

class _StatisticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      children: [
        _StatCard(
          title: 'Événements',
          value: '156',
          icon: Icons.event,
        ),
        _StatCard(
          title: 'Utilisateurs',
          value: '1,234',
          icon: Icons.people,
        ),
        _StatCard(
          title: 'Réservations',
          value: '892',
          icon: Icons.confirmation_number,
        ),
        _StatCard(
          title: 'Réclamations',
          value: '23',
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