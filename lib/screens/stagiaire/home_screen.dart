import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cmc_ev/models/event.dart';
import 'package:cmc_ev/models/user.dart';
import 'package:cmc_ev/models/comment.dart';
import 'package:cmc_ev/services/auth_service.dart';
import 'package:cmc_ev/services/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Event> _events = [];
  bool _isLoading = true;
  String _selectedCategory = 'All Events';

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      var query = _supabase.from('events').select('''
        *,
        users!creator_id(username, profile_picture),
        reservations!event_id(count),
        likes!event_id(user_id),
        comments!event_id(*, users!user_id(username, profile_picture))
      ''');

      // Apply filters
      query = query.filter('is_completed', 'eq', false);

      if (_selectedCategory != 'All Events') {
        query = query.filter('category', 'eq', _selectedCategory.toLowerCase());
      }

      final response = await query.order('start_date', ascending: true);

      final events = response.map((e) {
        return Event.fromMap({
          ...e,
          'organizerName': e['users']['username'],
          'organizerImageUrl': e['users']['profile_picture'],
          'currentAttendees': e['reservations'].isNotEmpty ? e['reservations'][0]['count'] : 0,
          'likes': e['likes'].map((l) => l['user_id']).toList(),
          'comments': e['comments'].map((c) => {
                ...c,
                'username': c['users']['username'],
                'profile_picture': c['users']['profile_picture'],
              }).toList(),
        });
      }).toList();

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des événements')),
        );
      }
    }
  }

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
                    'Catégories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          // TODO: Implement search
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {
                          // TODO: Implement notifications
                        },
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
                  _buildCategoryChip('All Events', _selectedCategory == 'All Events'),
                  _buildCategoryChip('Sport', _selectedCategory == 'Sport'),
                  _buildCategoryChip('Culture', _selectedCategory == 'Culture'),
                  _buildCategoryChip('Competition', _selectedCategory == 'Competition'),
                  _buildCategoryChip('Other', _selectedCategory == 'Other'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _events.isEmpty
                      ? const Center(child: Text('Aucun événement trouvé'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            return EventCard(
                              event: _events[index],
                              onEventUpdated: _fetchEvents,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = label;
              _isLoading = true;
            });
            _fetchEvents();
          }
        },
        selectedColor: const Color(0xFF37A2BC),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback onEventUpdated;

  const EventCard({super.key, required this.event, required this.onEventUpdated});

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  bool? _isFollowing;
  bool _isLiked = false;
  bool _isRegistered = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkFollowing();
    _checkLikeStatus();
    _checkRegistrationStatus();
  }

  Future<void> _checkFollowing() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId != null) {
      final response = await _supabase
          .from('follows')
          .select()
          .filter('follower_id', 'eq', userId)
          .filter('followed_id', 'eq', widget.event.creatorId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isFollowing = response != null;
        });
      }
    }
  }

  Future<void> _checkLikeStatus() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId != null) {
      final response = await _supabase
          .from('likes')
          .select()
          .filter('user_id', 'eq', userId)
          .filter('event_id', 'eq', widget.event.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isLiked = response != null;
        });
      }
    }
  }

  Future<void> _checkRegistrationStatus() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId != null) {
      final response = await _supabase
          .from('reservations')
          .select()
          .filter('user_id', 'eq', userId)
          .filter('event_id', 'eq', widget.event.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isRegistered = response != null;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour aimer')),
      );
      return;
    }

    try {
      if (_isLiked) {
        await _supabase
            .from('likes')
            .delete()
            .filter('user_id', 'eq', userId)
            .filter('event_id', 'eq', widget.event.id);
      } else {
        await _supabase.from('likes').insert({
          'id': const Uuid().v4(),
          'user_id': userId,
          'event_id': widget.event.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
        });
        widget.onEventUpdated();
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour du like')),
      );
    }
  }

  Future<void> _toggleRegistration() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour vous inscrire')),
      );
      return;
    }

    try {
      if (_isRegistered) {
        await _supabase
            .from('reservations')
            .delete()
            .filter('user_id', 'eq', userId)
            .filter('event_id', 'eq', widget.event.id);
      } else {
        await _supabase.from('reservations').insert({
          'id': const Uuid().v4(),
          'user_id': userId,
          'event_id': widget.event.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      if (mounted) {
        setState(() {
          _isRegistered = !_isRegistered;
        });
        widget.onEventUpdated();
      }
    } catch (e) {
      print('Error toggling registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'inscription')),
      );
    }
  }

  Future<void> _postComment(String text) async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour commenter')),
      );
      return;
    }

    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le commentaire ne peut pas être vide')),
      );
      return;
    }

    try {
      await _supabase.from('comments').insert({
        'id': const Uuid().v4(),
        'event_id': widget.event.id,
        'user_id': userId,
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
      _commentController.clear();
      widget.onEventUpdated();
    } catch (e) {
      print('Error posting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi du commentaire')),
      );
    }
  }

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
        builder: (_, controller) => CommentsSection(
          event: widget.event,
          controller: controller,
          onCommentPosted: _postComment,
          commentController: _commentController,
        ),
      ),
    );
  }

  void _shareEvent(BuildContext context) {
    Share.share(
      'Découvrez cet événement : ${widget.event.title} à ${widget.event.location} le ${widget.event.startDate.toString()}',
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.event.organizerImageUrl != null
                      ? NetworkImage(widget.event.organizerImageUrl!)
                      : null,
                  child: widget.event.organizerImageUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.organizerName ?? 'Stagiaire',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'Publié ${timeago.format(widget.event.startDate, locale: 'fr')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final userId = _authService.getCurrentUser()?.id;
                    if (userId != null) {
                      await _profileService.followUser(
                        userId,
                        widget.event.creatorId,
                        !_isFollowing!,
                      );
                      if (mounted) {
                        setState(() {
                          _isFollowing = !_isFollowing!;
                        });
                      }
                    }
                  },
                  child: Text(_isFollowing == null
                      ? 'Chargement...'
                      : _isFollowing!
                          ? 'Abonné'
                          : 'Suivre'),
                ),
              ],
            ),
          ),
          if (widget.event.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                widget.event.imageUrl!,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(widget.event.category),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${widget.event.startDate.day}/${widget.event.startDate.month}/${widget.event.startDate.year}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.event.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.event.location ?? 'Aucun lieu',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.event.currentAttendees ?? 0}/${widget.event.maxAttendees ?? '∞'} participants',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: widget.event.maxAttendees != null
                          ? (widget.event.currentAttendees ?? 0) / widget.event.maxAttendees!
                          : 0,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _toggleLike,
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : null,
                      ),
                      label: Text(_isLiked ? 'Aimé' : 'J\'aime'),
                    ),
                    ElevatedButton(
                      onPressed: _toggleRegistration,
                      child: Text(_isRegistered ? 'Désinscrit' : 'S\'inscrire'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SocialButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  count: widget.event.likes?.length ?? 0,
                  onPressed: _toggleLike,
                ),
                _SocialButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  count: widget.event.comments?.length ?? 0,
                  onPressed: () => _showComments(context),
                ),
                _SocialButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: () => _shareEvent(context),
                ),
                ElevatedButton(
                  onPressed: _toggleRegistration,
                  child: Text(_isRegistered ? 'Désinscrit' : 'Register'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

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

class CommentsSection extends StatelessWidget {
  final Event event;
  final ScrollController controller;
  final Function(String) onCommentPosted;
  final TextEditingController commentController;

  const CommentsSection({
    super.key,
    required this.event,
    required this.controller,
    required this.onCommentPosted,
    required this.commentController,
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
                'Commentaires',
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
            itemCount: event.comments?.length ?? 0,
            itemBuilder: (context, index) {
              final comment = event.comments![index];
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
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
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
                  onPressed: () => onCommentPosted(commentController.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
            backgroundImage: comment.userImageUrl != null
                ? NetworkImage(comment.userImageUrl!)
                : null,
            child: comment.userImageUrl == null ? const Icon(Icons.person) : null,
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
                      timeago.format(comment.createdAt, locale: 'fr'),
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