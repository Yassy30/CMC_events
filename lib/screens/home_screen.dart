import 'package:cmc_ev/models/event.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildCategoryChip('All Events', true),
                  _buildCategoryChip('Sport', false),
                  _buildCategoryChip('Music', false),
                  _buildCategoryChip('Art', false),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: 10, // Will be replaced with actual events length
                itemBuilder: (context, index) {
                  return EventCard(
                    event: Event(
                      id: '1',
                      title: 'Workshop Flutter',
                      description: 'Apprenez à créer des applications mobiles avec Flutter',
                      imageUrl: 'https://example.com/image.jpg',
                      date: DateTime.now().add(const Duration(days: 2)),
                      location: 'CMC Agadir - Salle 201',
                      maxAttendees: 30,
                      currentAttendees: 15,
                      organizerId: '123',
                      isFree: true,
                      category: 'Technology',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => CommentsSection(event: event, controller: controller),
      ),
    );
  }

  void _shareEvent(BuildContext context) {
    // Implement share functionality
    Share.share(
      'Check out this event: ${event.title} at ${event.location} on ${event.date.toString()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event organizer header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(event.organizerImageUrl ?? ''),
                  onBackgroundImageError: (_, __) => const Icon(Icons.person),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.organizerName ?? 'Stagiaire',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'Posted ${timeago.format(event.date)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Implement follow/unfollow logic
                    // This should be handled by your state management solution
                  },
                  child: Text(event.isFollowing ? 'Following' : 'Follow'),
                ),
              ],
            ),
          ),
          // Image de l'événement
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              event.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Catégorie et Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(event.category),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${event.date.day}/${event.date.month}/${event.date.year}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Titre
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                // Localisation
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Barre de progression des participants
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${event.currentAttendees}/${event.maxAttendees} participants',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: event.currentAttendees / event.maxAttendees,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('J\'aime'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('S\'inscrire'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Social interaction buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SocialButton(
                  icon: Icons.favorite_border,
                  label: 'Like',
                  count: event.likes.length,
                  onPressed: () {
                    // Implement like logic
                  },
                ),
                _SocialButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  count: event.comments.length,
                  onPressed: () => _showComments(context),
                ),
                _SocialButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: () => _shareEvent(context),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Implement registration logic
                  },
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for social buttons
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        count != null ? '$label ($count)' : label,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

// Comments section widget
class CommentsSection extends StatelessWidget {
  final Event event;
  final ScrollController controller;

  const CommentsSection({
    super.key,
    required this.event,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: event.comments.length,
            itemBuilder: (context, index) {
              final comment = event.comments[index];
              return CommentTile(comment: comment);
            },
          ),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Implement send comment logic
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Comment tile widget
class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(comment.userImageUrl ?? ''),
            onBackgroundImageError: (_, __) => const Icon(Icons.person),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
