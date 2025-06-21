import 'package:cmc_ev/models/comment.dart' as model;
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
  String _selectedTab = 'All'; // Options: 'All', 'Upcoming', 'Past'
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All Events', 'icon': Icons.event},
    {'name': 'Art & Design', 'icon': Icons.brush_outlined},
    {'name': 'Sports', 'icon': Icons.sports_basketball_outlined},
    {'name': 'Competition', 'icon': Icons.sports_esports_outlined},
    {'name': 'Culture', 'icon': Icons.theater_comedy_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final allEvents = await _eventService.getEvents();
      
      setState(() {
        _events = allEvents;
        _filterEvents();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterEvents() {
    // First filter by category
    var filtered = _events;
    if (_selectedCategory != 'All Events') {
      filtered = filtered.where((event) {
        // Make case-insensitive comparison and handle category mapping
        final normalizedEventCategory = _normalizeCategoryName(event.category.toLowerCase());
        final normalizedSelectedCategory = _selectedCategory.toLowerCase();
        return normalizedEventCategory == normalizedSelectedCategory;
      }).toList();
    }
    
    // Then filter by time (All, Upcoming, or Past)
    final now = DateTime.now();
    if (_selectedTab == 'Upcoming') {
      filtered = filtered.where((event) => event.startDate.isAfter(now)).toList();
      // Sort by closest first
      filtered.sort((a, b) => a.startDate.compareTo(b.startDate));
    } else if (_selectedTab == 'Past') {
      filtered = filtered.where((event) => event.startDate.isBefore(now)).toList();
      // Sort by most recent first
      filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
    } else {
      // For "All" tab, sort by date (newest first)
      filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
    }
    
    setState(() {
      _filteredEvents = filtered;
    });
  }

  // Helper method to normalize category names between screens
  String _normalizeCategoryName(String category) {
    // Map from database categories to display categories
    final Map<String, String> categoryMap = {
      'sport': 'sports',
      'culture': 'culture',
      'competition': 'competition',
      'art_design': 'art & design',
      'other': 'other',
    };
    
    return categoryMap[category.toLowerCase()] ?? category.toLowerCase();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterEvents();
  }

  void _onTabSelected(String tab) {
    setState(() {
      _selectedTab = tab;
    });
    _filterEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : Column(
                children: [
                  // Fixed Header - Contains both app bar and category filters
                  // Use Material widget with elevation: 0 to prevent color shifts during scroll
                  Material(
                    color: Colors.white, // Explicit white color
                    elevation: 0, // No shadow
                    child: Column(
                      children: [
                        // App Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text(
                                  "IN'CMC",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Spacer(),
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.black),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.notifications_none, color: Colors.black),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        
                        // Categories Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Categories',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Categories Scrollable Row
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              return _buildCategoryPill(
                                _categories[index]['name'],
                                _categories[index]['icon'],
                              );
                            },
                          ),
                        ),
                        
                        // Event filter tabs (All, Upcoming, Past) - NOW FIXED
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              _buildFilterTab('All', _selectedTab == 'All'),
                              const SizedBox(width: 16),
                              _buildFilterTab('Upcoming', _selectedTab == 'Upcoming'),
                              const SizedBox(width: 16),
                              _buildFilterTab('Past', _selectedTab == 'Past'),
                            ],
                          ),
                        ),

                        // Add a subtle divider to separate fixed and scrollable content
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                  ),
                  
                  // Scrollable content starts here
                  Expanded(
                    child: _filteredEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No events found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try changing your filters',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: SmallEventCard(event: _filteredEvents[index]),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterTab(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => _onTabSelected(text),
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14, // Slightly smaller
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 3,
              width: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      ),
    );
  }

  // UPDATED: Smaller category pills
  Widget _buildCategoryPill(String category, IconData icon) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        margin: const EdgeInsets.only(right: 8), // Smaller margin
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Smaller padding
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF37A2BC) 
              : Colors.white,
          borderRadius: BorderRadius.circular(16), // Slightly smaller radius
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF37A2BC) 
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14, // Smaller icon
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 4), // Smaller spacing
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontSize: 11, // Smaller text
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// UPDATED: Smaller EventCard
class SmallEventCard extends StatefulWidget {
  final Event event;

  const SmallEventCard({super.key, required this.event});

  @override
  State<SmallEventCard> createState() => _SmallEventCardState();
}

class _SmallEventCardState extends State<SmallEventCard> {
  final _eventService = EventService();
  final _likeService = LikeService();
  final _commentService = CommentService();
  final _authService = AuthService();
  
  int _likesCount = 0;
  int _commentsCount = 0;
  bool _isLiked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    try {
      final likesCountFuture = _likeService.getLikesCount(widget.event.id);
      final commentsCountFuture = _eventService.getCommentsCount(widget.event.id);
      
      List<dynamic> results = [0, 0, false];
      
      if (_authService.isLoggedIn) {
        final userId = _authService.currentUserId;
        final isLikedFuture = _likeService.isEventLikedByUser(widget.event.id, userId);
        
        results = await Future.wait([
          likesCountFuture,
          commentsCountFuture,
          isLikedFuture,
        ]);
      } else {
        final partialResults = await Future.wait([
          likesCountFuture,
          commentsCountFuture,
        ]);
        
        results[0] = partialResults[0];
        results[1] = partialResults[1];
      }
      
      if (mounted) {
        setState(() {
          _likesCount = results[0] as int;
          _commentsCount = results[1] as int;
          _isLiked = _authService.isLoggedIn ? (results[2] as bool) : false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading event data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (!_authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like events'))
      );
      return;
    }

    try {
      final userId = _authService.currentUserId;
      final wasLiked = _isLiked;
      
      final isLiked = await _likeService.toggleLike(widget.event.id, userId);
      
      if (mounted) {
        setState(() {
          if (wasLiked != isLiked) {
            _likesCount = isLiked ? _likesCount + 1 : _likesCount - 1;
          }
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
  }

  void _showEventDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsFullPage(event: widget.event),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scrollController = ScrollController();
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: CommentsSection(
                  eventId: widget.event.id,
                  controller: scrollController,
                  onCommentAdded: () async {
                    final commentsCount = await _eventService.getCommentsCount(widget.event.id);
                    if (mounted) {
                      setState(() {
                        _commentsCount = commentsCount;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareEvent(BuildContext context) {
    Share.share(
      'Join this event: ${widget.event.title} at ${widget.event.location ?? 'TBD'} on ${DateFormat('yyyy-MM-dd HH:mm').format(widget.event.startDate)}! Category: ${widget.event.category}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image - MADE SMALLER
          GestureDetector(
            onTap: () => _showEventDetails(context),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 8, // Smaller aspect ratio
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Smaller padding
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12), // Smaller radius
                    ),
                    child: Text(
                      widget.event.paymentType == 'paid' ? 'Paid' : 'Free',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10, // Smaller text
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Title and Event Info - MADE SMALLER
          Padding(
            padding: const EdgeInsets.all(10.0), // Smaller padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Smaller text
                  ),
                  maxLines: 1, // Single line title
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 6), // Smaller spacing
                
                // Location with icon
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined, 
                      size: 12, // Smaller icon
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.event.location ?? 'No location specified',
                        style: TextStyle(
                          fontSize: 11, // Smaller text
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 2), // Smaller spacing
                
                // Date with icon
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined, 
                      size: 12, // Smaller icon
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      DateFormat('E, MMM d • h:mm a').format(widget.event.startDate), // Shorter date format
                      style: TextStyle(
                        fontSize: 11, // Smaller text
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8), // Smaller spacing
                
                // Social interaction buttons
                Row(
                  children: [
                    // Like button
                    _buildSocialAction(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      text: '$_likesCount',
                      onTap: _toggleLike,
                      isActive: _isLiked,
                      color: _isLiked ? Colors.red : Colors.grey[600],
                    ),
                    
                    SizedBox(width: 12), // Smaller spacing
                    
                    // Comment button
                    _buildSocialAction(
                      icon: Icons.chat_bubble_outline,
                      text: '$_commentsCount',
                      onTap: () => _showComments(context),
                      color: Colors.grey[600],
                    ),
                    
                    SizedBox(width: 12), // Smaller spacing
                    
                    // Share button
                    _buildSocialAction(
                      icon: Icons.share_outlined,
                      text: 'Share',
                      onTap: () => _shareEvent(context),
                      color: Colors.grey[600],
                    ),
                    
                    Spacer(),
                    
                    // Details button - MADE SMALLER
                    OutlinedButton(
                      onPressed: () => _showEventDetails(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: Size(0, 24), // Smaller height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: theme.colorScheme.primary, width: 1),
                      ),
                      child: Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 10, // Smaller text
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Smaller social action buttons
  Widget _buildSocialAction({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14, // Smaller icon
              color: color,
            ),
            SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 11, // Smaller text
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      )
      );
  }
}

// Event Details Full Page for navigation
class EventDetailsFullPage extends StatelessWidget {
  final Event event;
  
  const EventDetailsFullPage({super.key, required this.event});
  
  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    return Scaffold(
      body: EventDetailsView(
        event: event,
        controller: controller,
      ),
    );
  }
}

// Event Card with updated design to match the mockup
class EventCard extends StatefulWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final _eventService = EventService();
  final _likeService = LikeService();
  final _commentService = CommentService();
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
    try {
      final likesCountFuture = _likeService.getLikesCount(widget.event.id);
      final commentsCountFuture = _eventService.getCommentsCount(widget.event.id);
      final reservationsCountFuture = _eventService.getReservationsCount(widget.event.id);
      
      List<dynamic> results = [0, 0, 0, false];
      
      if (_authService.isLoggedIn) {
        final userId = _authService.currentUserId;
        final isLikedFuture = _likeService.isEventLikedByUser(widget.event.id, userId);
        
        results = await Future.wait([
          likesCountFuture,
          commentsCountFuture,
          reservationsCountFuture,
          isLikedFuture,
        ]);
      } else {
        final partialResults = await Future.wait([
          likesCountFuture,
          commentsCountFuture,
          reservationsCountFuture,
        ]);
        
        results[0] = partialResults[0];
        results[1] = partialResults[1];
        results[2] = partialResults[2];
      }
      
      if (mounted) {
        setState(() {
          _likesCount = results[0] as int;
          _commentsCount = results[1] as int;
          _reservationsCount = results[2] as int;
          _isLiked = _authService.isLoggedIn ? (results[3] as bool) : false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading event data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (!_authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like events'))
      );
      return;
    }

    try {
      final userId = _authService.currentUserId;
      // Store previous state to compare later
      final wasLiked = _isLiked;
      
      // Toggle like in database
      final isLiked = await _likeService.toggleLike(widget.event.id, userId);
      
      if (mounted) {
        setState(() {
          // Only update count if there's an actual change
          if (wasLiked != isLiked) {
            _likesCount = isLiked ? _likesCount + 1 : _likesCount - 1;
          }
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
  }

  void _showEventDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsFullPage(event: widget.event),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Create a controller for the comments scrolling
        final scrollController = ScrollController();
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Comment list with callback
              Expanded(
                child: CommentsSection(
                  eventId: widget.event.id,
                  controller: scrollController,
                  onCommentAdded: () async {
                    // Refresh the comments count
                    final commentsCount = await _eventService.getCommentsCount(widget.event.id);
                    if (mounted) {
                      setState(() {
                        _commentsCount = commentsCount;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareEvent(BuildContext context) {
    Share.share(
      'Join this event: ${widget.event.title} at ${widget.event.location ?? 'TBD'} on ${DateFormat('yyyy-MM-dd HH:mm').format(widget.event.startDate)}! Category: ${widget.event.category}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image (Clickable to show details)
          GestureDetector(
            onTap: () => _showEventDetails(context),
            child: Stack(
              children: [
                AspectRatio(
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.event.paymentType == 'paid' ? 'Paid' : 'Free',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Title and Event Info
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 6),
                
                // Location with icon
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined, 
                      size: 12, 
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.event.location ?? 'No location specified',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 2),
                
                // Date with icon
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined, 
                      size: 12, 
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      DateFormat('E, MMM d • h:mm a').format(widget.event.startDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // Social interaction buttons
                Row(
                  children: [
                    // Like button
                    _buildSocialAction(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      text: '$_likesCount',
                      onTap: _toggleLike,
                      isActive: _isLiked,
                      color: _isLiked ? Colors.red : Colors.grey[600],
                    ),
                    
                    SizedBox(width: 12),
                    
                    // Comment button
                    _buildSocialAction(
                      icon: Icons.chat_bubble_outline,
                      text: '$_commentsCount',
                      onTap: () => _showComments(context),
                      color: Colors.grey[600],
                    ),
                    
                    SizedBox(width: 12),
                    
                    // Share button
                    _buildSocialAction(
                      icon: Icons.share_outlined,
                      text: 'Share',
                      onTap: () => _shareEvent(context),
                      color: Colors.grey[600],
                    ),
                    
                    Spacer(),
                    
                    // Details button - MADE SMALLER
                    OutlinedButton(
                      onPressed: () => _showEventDetails(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: Size(0, 24), // Smaller height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: theme.colorScheme.primary, width: 1),
                      ),
                      child: Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 10, // Smaller text
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialAction({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14, // Smaller icon
              color: color,
            ),
            SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 11, // Smaller text
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      )
      );
  }
}

class CommentsSection extends StatefulWidget {
  final String eventId;
  final ScrollController controller;
  final VoidCallback? onCommentAdded;

  const CommentsSection({
    super.key,
    required this.eventId,
    required this.controller,
    this.onCommentAdded,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _commentService = CommentService();
  final _authService = AuthService();
  final _commentController = TextEditingController();
  List<model.Comment> _comments = [];
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
      
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        
        // Notify parent when comment is added
        if (widget.onCommentAdded != null) {
          widget.onCommentAdded!();
        }
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
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Be the first to comment!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: widget.controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _comments.length,
                      separatorBuilder: (context, index) => Divider(height: 24),
                      itemBuilder: (context, index) {
                        return CommentTile(comment: _comments[index]);
                      },
                    ),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.person, color: Colors.grey[500]),
                ),
                SizedBox(width: 12),
                // Comment input field
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Send button
                _isSending
                    ? SizedBox(
                        height: 36,
                        width: 36,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.send, color: Colors.white, size: 16),
                          onPressed: _sendComment,
                          padding: EdgeInsets.zero,
                        ),
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
  final model.Comment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    // Fix date display with proper formatting
    String formattedTime;
    final now = DateTime.now();
    final difference = now.difference(comment.createdAt);
    
    if (difference.inSeconds < 60) {
      formattedTime = 'Just now';
    } else if (difference.inMinutes < 60) {
      formattedTime = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      formattedTime = '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      formattedTime = '${difference.inDays}d ago';
    } else {
      formattedTime = DateFormat('MMM d, y').format(comment.createdAt);
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: comment.userImageUrl != null
              ? NetworkImage(comment.userImageUrl!)
              : null,
          backgroundColor: Colors.grey[200],
          child: comment.userImageUrl == null
              ? Icon(Icons.person, color: Colors.grey[600], size: 20)
              : null,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Username with verified badge if needed
                  Text(
                    comment.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  // Time ago
                  Text(
                    formattedTime,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              // Comment text
              Text(
                comment.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              // Comment actions
              SizedBox(height: 8),
              Row(
                children: [
                  _buildCommentAction('Like'),
                  SizedBox(width: 16),
                  _buildCommentAction('Reply'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCommentAction(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: Colors.grey[600],
      ),
    );
  }
}