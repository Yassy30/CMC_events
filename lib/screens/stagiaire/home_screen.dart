import 'package:cmc_ev/models/comment.dart';
import 'package:cmc_ev/models/event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cmc_ev/services/event_service.dart';
import 'package:cmc_ev/services/comment_service.dart';
import 'package:cmc_ev/services/like_service.dart';
import 'package:cmc_ev/services/auth_service.dart';
import 'package:cmc_ev/screens/stagiaire/event_details_view.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _eventService = EventService();
  final _authService = AuthService();
  String _selectedCategory = 'All Events';
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final events = await _eventService.getEvents(
        category: _selectedCategory == 'All Events' ? null : _selectedCategory
      );
      
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All Events', 'sport', 'culture', 'competition', 'other'];
    
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
                children: categories.map((category) {
                  return _buildCategoryChip(
                    category, 
                    _selectedCategory == category,
                    () => _onCategorySelected(category)
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                  ? const Center(child: Text('No events found'))
                  : RefreshIndicator(
                      onRefresh: _loadEvents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          return EventCard(event: _events[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected ? const Color(0xFF37A2BC) : Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class EventCard extends StatefulWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final _eventService = EventService();
  final _likeService = LikeService();
  final _authService = AuthService();
  
  int _likesCount = 0;
  int _commentsCount = 0;
  int _reservationsCount = 0;
  bool _isLiked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    if (_authService.isLoggedIn) {
      final userId = _authService.currentUserId;
      
      final likesCountFuture = _likeService.getLikesCount(widget.event.id);
      final commentsCountFuture = _eventService.getCommentsCount(widget.event.id);
      final reservationsCountFuture = _eventService.getReservationsCount(widget.event.id);
      final isLikedFuture = _likeService.isEventLikedByUser(widget.event.id, userId);
      
      final results = await Future.wait([
        likesCountFuture,
        commentsCountFuture,
        reservationsCountFuture,
        isLikedFuture,
      ]);
      
      setState(() {
        _likesCount = results[0] as int;
        _commentsCount = results[1] as int;
        _reservationsCount = results[2] as int;
        _isLiked = results[3] as bool;
        _isLoading = false;
      });
    } else {
      final likesCountFuture = _likeService.getLikesCount(widget.event.id);
      final commentsCountFuture = _eventService.getCommentsCount(widget.event.id);
      final reservationsCountFuture = _eventService.getReservationsCount(widget.event.id);
      
      final results = await Future.wait([
        likesCountFuture,
        commentsCountFuture,
        reservationsCountFuture,
      ]);
      
      setState(() {
        _likesCount = results[0] as int;
        _commentsCount = results[1] as int;
        _reservationsCount = results[2] as int;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (!_authService.isLoggedIn) {
      // Show login prompt
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like events'))
      );
      return;
    }

    try {
      final userId = _authService.currentUserId;
      final isLiked = await _likeService.toggleLike(widget.event.id, userId);
      
      setState(() {
        _isLiked = isLiked;
        _likesCount += isLiked ? 1 : -1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
  }

  void _showEventDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => EventDetailsView(
          event: widget.event,
          controller: controller,
        ),
      ),
    );
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
          eventId: widget.event.id,
          controller: controller,
        ),
      ),
    );
  }

  void _shareEvent(BuildContext context) {
    Share.share(
      'Join this event: ${widget.event.title} at ${widget.event.location ?? 'TBD'} on ${DateFormat('yyyy-MM-dd HH:mm').format(widget.event.startDate)}! Category: ${widget.event.category}',
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
          // Event organizer header (using creatorId)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.event.creatorImageUrl ?? 'https://example.com/organizer.jpg'),
                  onBackgroundImageError: (_, __) => const Icon(Icons.person),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.creatorName ?? 'Organizer',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'Posted ${timeago.format(widget.event.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Implement follow/unfollow logic
                  },
                  child: const Text('Follow'),
                ),
              ],
            ),
          ),
          // Event Image (Clickable to show details)
          GestureDetector(
            onTap: () => _showEventDetails(context),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                widget.event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category and Date
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
                      DateFormat('dd/MM/yyyy').format(widget.event.startDate),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Title (Clickable to show details)
                GestureDetector(
                  onTap: () => _showEventDetails(context),
                  child: Text(
                    widget.event.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.event.location ?? 'Location not specified',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Attendees Progress
                if (widget.event.maxAttendees != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_reservationsCount/${widget.event.maxAttendees} participants',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: widget.event.maxAttendees! > 0
                            ? _reservationsCount / widget.event.maxAttendees!
                            : 0,
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
                      onPressed: _toggleLike,
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : null,
                      ),
                      label: Text(_isLiked ? 'Liked' : 'Like'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implement registration logic
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Social interaction buttons
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                // Like button - redesigned
                Expanded(
                  child: InkWell(
                    onTap: _toggleLike,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: _isLiked ? Colors.red : Colors.grey[700],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_likesCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isLiked ? Colors.red : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Comment button - redesigned
                Expanded(
                  child: InkWell(
                    onTap: () => _showComments(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_commentsCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Share button - redesigned
                Expanded(
                  child: InkWell(
                    onTap: () => _shareEvent(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Register button - redesigned
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // TODO: Implement registration logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registration coming soon')),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18, 
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentsSection extends StatefulWidget {
  final String eventId;
  final ScrollController controller;

  const CommentsSection({
    super.key,
    required this.eventId,
    required this.controller,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _commentService = CommentService();
  final _authService = AuthService();
  final _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final comments = await _commentService.getCommentsForEvent(widget.eventId);
      
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    if (!_authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment'))
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final userId = _authService.currentUserId;
      final comment = await _commentService.addComment(
        widget.eventId,
        userId,
        _commentController.text.trim(),
      );
      
      if (comment != null) {
        setState(() {
          _comments.insert(0, comment);
          _commentController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send comment: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

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
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                  ? const Center(child: Text('No comments yet'))
                  : ListView.builder(
                      controller: widget.controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        return CommentTile(comment: _comments[index]);
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
                    controller: _commentController,
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
                _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendComment,
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