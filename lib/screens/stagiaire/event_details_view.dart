import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../services/like_service.dart';
import '../../services/comment_service.dart';
import '../../models/comment.dart';
import '../payment/payment_method_screen.dart';
import '../payment/payment_success_screen.dart';

class EventDetailsView extends StatefulWidget {
  final Event event;
  final ScrollController controller;
 
  const EventDetailsView({
    super.key,
    required this.event,
    required this.controller,
  });

  @override
  State<EventDetailsView> createState() => _EventDetailsViewState();
}

class _EventDetailsViewState extends State<EventDetailsView> {
  final _eventService = EventService();
  final _authService = AuthService();
  final _likeService = LikeService();
  final _commentService = CommentService();
  
  int _reservationsCount = 0;
  bool _isLoading = true;
  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get reservation count
      _reservationsCount = await _eventService.getReservationsCount(widget.event.id);
      
      // Check if the current user has liked this event
      final userId = _authService.currentUserId;
      if (_authService.isLoggedIn) {
        _isLiked = await _likeService.checkIfLiked(widget.event.id, userId);
      }
      
      // Get likes count
      _likesCount = await _likeService.getLikesCount(widget.event.id);
      
      // Get comments count
      _commentsCount = await _commentService.getCommentsCount(widget.event.id);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading data: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (!_authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like events')),
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
          // Only update count if there's an actual change in state
          if (wasLiked != isLiked) {
            _likesCount = isLiked ? _likesCount + 1 : _likesCount - 1;
          }
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Update the _registerForEvent method to handle refreshing data properly
  Future<void> _registerForEvent() async {
    if (!_authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to register for events')),
      );
      return;
    }

    try {
      final userId = _authService.currentUserId;
      
      // Check if user is already registered
      final isAlreadyRegistered = await _eventService.isUserRegistered(widget.event.id, userId);
      
      if (isAlreadyRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are already registered for this event')),
        );
        return;
      }

      // Check if event is full before registration attempt
      if (widget.event.maxAttendees != null && _reservationsCount >= widget.event.maxAttendees!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sorry, this event is fully booked')),
        );
        return;
      }

      // Register for the event
      final success = await _eventService.registerForEvent(widget.event.id, userId);
      
      if (!success) {
        // If registration failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. You may already be registered.')),
        );
        return;
      }

      if (widget.event.paymentType == 'free') {
        // For free events, update UI immediately
        await _loadData(); // Reload all data to ensure accurate count
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! You\'re all set.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // For paid events, navigate to payment screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentMethodScreen(event: widget.event),
            settings: const RouteSettings(name: '/payment'),
          ),
        );
        
        print('Payment result: $result'); // Debug print
        
        // If payment was successful
        if (result == true) {
          await _eventService.completePayment(widget.event.id, userId);
          
          // Important: Refresh data to show updated spots
          // This is likely where it's failing to refresh
          if (mounted) {
            setState(() {
              _isLoading = true; // Show loading indicator
            });
            
            // Get updated reservation count
            _reservationsCount = await _eventService.getReservationsCount(widget.event.id);
            
            setState(() {
              _isLoading = false;
            });
            
            // Show confirmation to user
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! You\'re registered for the event.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      // Make app bar completely transparent
      appBar: PreferredSize(
        // Reduce app bar height to minimize white space
        preferredSize: const Size.fromHeight(kToolbarHeight - 8),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          // Remove top padding
          toolbarHeight: kToolbarHeight - 8,
          // Move buttons higher up
          leading: Container(
            margin: const EdgeInsets.only(left: 16.0, top: 4.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 20,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Like button
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16.0, top: 4.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 20,
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                ),
                onPressed: _toggleLike,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
            children: [
              // Main content scrollview
              SingleChildScrollView(
                controller: widget.controller,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fix 2: Ensure image takes full width and proper height with no spacing
                    Stack(
                      children: [
                        // Ensure image goes to the very top - no padding/margin
                        Container(
                          height: size.height * 0.45,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.black, // Black background for image
                          ),
                          child: Image.network(
                            widget.event.imageUrl,
                            fit: BoxFit.cover,
                            height: size.height * 0.45,
                            width: double.infinity,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                              );
                            },
                          ),
                        ),
                        
                        // Bottom gradient overlay (subtle)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Bottom curve overlay
                        Positioned(
                          bottom: -2, // Change from -1 to -2 to ensure overlap
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 24, // Increase from 20 to 24
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        
                        // Minimal title only at the bottom
                        Positioned(
                          bottom: 30,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category tag (single most important tag only)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.event.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Event title with shadow
                              Text(
                                widget.event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Rest of your content (keep as is)
                    const SizedBox(height: 16),
                    
                    // Category chips - scrollable row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildCategoryChip(
                            widget.event.category,
                            Icons.category_outlined,
                            theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          _buildCategoryChip(
                            widget.event.paymentType == 'paid' ? 'Paid' : 'Free',
                            widget.event.paymentType == 'paid' ? Icons.paid : Icons.money_off,
                            widget.event.paymentType == 'paid' ? Colors.amber[700]! : Colors.green,
                          ),
                        ],
                      ),
                    ),
                    
                    // Event date and location information
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.event, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMMM, yyyy').format(widget.event.startDate),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.event.location ?? 'No location specified',
                              style: TextStyle(color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Event card
                    _buildInfoCard(
                      'Event Details',
                      widget.event.description ?? 'No description provided',
                      Icons.info_outline,
                      theme.colorScheme.primary,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Organizer card
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(
                                widget.event.creatorImageUrl ?? 'https://via.placeholder.com/100',
                              ),
                              backgroundColor: Colors.grey[200],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Organized by',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.event.creatorName ?? 'Event Organizer',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                // Navigate to organizer profile
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                side: BorderSide(color: theme.colorScheme.primary),
                              ),
                              child: Text(
                                'Follow',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Stats card
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Event Stats',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn(
                                  Icons.access_time,
                                  DateFormat('HH:mm').format(widget.event.startDate),
                                  'Start Time',
                                ),
                                _buildStatColumn(
                                  Icons.people,
                                  '$_reservationsCount${widget.event.maxAttendees != null ? '/${widget.event.maxAttendees}' : ''}',
                                  'Attendees',
                                ),
                                _buildStatColumn(
                                  Icons.favorite,
                                  '$_likesCount',
                                  'Likes',
                                ),
                                _buildStatColumn(
                                  Icons.comment,
                                  '$_commentsCount',
                                  'Comments',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (widget.event.maxAttendees != null) ...[
                      const SizedBox(height: 12),
                      // Attendance card
                      Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_alt_outlined,
                                    color: _reservationsCount >= widget.event.maxAttendees!
                                        ? Colors.red
                                        : theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Attendance',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$_reservationsCount/${widget.event.maxAttendees} spots filled',
                                  ),
                                  Text(
                                    _reservationsCount >= widget.event.maxAttendees!
                                        ? 'Fully booked'
                                        : '${widget.event.maxAttendees! - _reservationsCount} spots left',
                                    style: TextStyle(
                                      color: _reservationsCount >= widget.event.maxAttendees!
                                          ? Colors.red
                                          : Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: widget.event.maxAttendees! > 0
                                      ? _reservationsCount / widget.event.maxAttendees!
                                      : 0,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _reservationsCount >= widget.event.maxAttendees!
                                        ? Colors.red
                                        : theme.colorScheme.primary,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Fix 3: Social interaction buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _toggleLike,
                              icon: Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                color: _isLiked ? Colors.red : Colors.grey[600],
                                size: 18,
                              ),
                              label: Text(
                                'Like ($_likesCount)',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCommentsDialog(context),
                              icon: Icon(
                                Icons.comment_outlined,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                              label: Text(
                                'Comments ($_commentsCount)',
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  // ADD SAVE BUTTON HERE - positioned between the interaction buttons and the spacer
                      Row(
                        children: [
    // Space between buttons                            const SizedBox(width: 8),
                            const SizedBox(width: 18),

                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Save logic will go here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Event saved to favorites')),
                                );
                              },
                              icon: Icon(
                                Icons.bookmark_border,
                                color: Theme.of(context).colorScheme.primary,
                                size: 18,
                              ),
                              label: Text(
                                'Save',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                      const EdgeInsets.symmetric(vertical: 10),                                side: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),
                                                      const SizedBox(width: 18),

                        ],
                      ),
                    
                    // Spacer
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
      
      // Bottom navigation bar
      bottomNavigationBar: _isLoading 
          ? null 
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _registerForEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    widget.event.paymentType == 'paid'
                        ? 'Register - ${widget.event.ticketPrice} MAD'
                        : 'Register for Free',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
  
  // Helper method for category chips
  Widget _buildCategoryChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method for info cards
  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method for stat columns
  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[700], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Fix 5: Add comments dialog function with callback for updating counts
  void _showCommentsDialog(BuildContext context) {
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
              // Comment list with improved UI
              Expanded(
                child: _EventDetailsCommentsSection(
                  eventId: widget.event.id,
                  controller: scrollController,
                  onCommentAdded: () async {
                    // Refresh the comment count when a new comment is added
                    final newCount = await _eventService.getCommentsCount(widget.event.id);
                    if (mounted) {
                      setState(() {
                        _commentsCount = newCount;
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
}

class _EventDetailsCommentsSection extends StatefulWidget {
  final String eventId;
  final ScrollController controller;
  final VoidCallback? onCommentAdded;

  const _EventDetailsCommentsSection({
    Key? key,
    required this.eventId,
    required this.controller,
    this.onCommentAdded,
  }) : super(key: key);

  @override
  State<_EventDetailsCommentsSection> createState() => _EventDetailsCommentsSectionState();
}

class _EventDetailsCommentsSectionState extends State<_EventDetailsCommentsSection> {
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
                        return _EventDetailsCommentTile(comment: _comments[index]);
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

class _EventDetailsCommentTile extends StatelessWidget {
  final Comment comment;

  const _EventDetailsCommentTile({Key? key, required this.comment}) : super(key: key);

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

// When you navigate to EventDetailsView in your app, use:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => EventDetailsView(
//       event: event,
//       controller: controller,
//     ),
//     settings: const RouteSettings(name: '/event_details'), // Add this line
//   ),
// );
