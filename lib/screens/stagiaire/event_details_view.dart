import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../services/like_service.dart';

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
  int _reservationsCount = 0;
  bool _isLoading = true;
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final reservationsCount = await _eventService.getReservationsCount(widget.event.id);
      final likesCount = await _likeService.getLikesCount(widget.event.id);
      final isLiked = _authService.isLoggedIn 
          ? await _likeService.isEventLikedByUser(widget.event.id, _authService.currentUserId)
          : false;
      
      if (mounted) {
        setState(() {
          _reservationsCount = reservationsCount;
          _likesCount = likesCount;
          _isLiked = isLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
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
        const SnackBar(content: Text('Please log in to like events')),
      );
      return;
    }

    try {
      final isLiked = await _likeService.toggleLike(
        widget.event.id, 
        _authService.currentUserId
      );
      
      setState(() {
        _isLiked = isLiked;
        _likesCount = isLiked ? _likesCount + 1 : _likesCount - 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              controller: widget.controller,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom SliverAppBar with adaptive sizing
                SliverAppBar(
                  expandedHeight: size.height * 0.4, // Increased from 0.25 to 0.4
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: kToolbarHeight,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.fadeTitle,
                    ],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Full-screen event image with enhanced gradient overlay
                        ShaderMask(
                          shaderCallback: (rect) {
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                                Colors.black.withOpacity(0.8)
                              ],
                              stops: const [0.3, 0.7, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.darken,
                          child: Image.network(
                            widget.event.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.broken_image, color: Colors.white, size: 40),
                              );
                            },
                            // Add image fade-in effect
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                                child: child,
                              );
                            },
                          ),
                        ),
                        
                        // Title and date positioned at bottom
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Categories and tags in row
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildTag(
                                      widget.event.category.toUpperCase(),
                                      theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTag(
                                      widget.event.paymentType == 'paid'
                                          ? '${widget.event.ticketPrice} MAD'
                                          : 'FREE',
                                      widget.event.paymentType == 'paid'
                                          ? Colors.amber
                                          : Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Event title with shadow for better readability
                              Text(
                                widget.event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22, // Slightly larger for better visibility
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Date row with icon
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      DateFormat('EEE, d MMM yyyy').format(widget.event.startDate),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
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
                  ),
                  // Back button with improved styling
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  // Actions with improved styling
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.white,
                          size: 18,
                        ),
                      ),
                      onPressed: _toggleLike,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // Content
                SliverToBoxAdapter(
                  child: Container(
                    color: theme.colorScheme.background,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event stats section - simple row
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                Icons.access_time_rounded,
                                DateFormat('HH:mm').format(widget.event.startDate),
                                'Time',
                                theme,
                              ),
                              _buildVerticalDivider(),
                              _buildStatItem(
                                Icons.people_alt_rounded,
                                '$_reservationsCount${widget.event.maxAttendees != null ? '/${widget.event.maxAttendees}' : ''}',
                                'Attendees',
                                theme,
                              ),
                              _buildVerticalDivider(),
                              _buildStatItem(
                                Icons.favorite_rounded,
                                '$_likesCount',
                                'Likes',
                                theme,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Organizer Card - simplified
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(
                                  widget.event.creatorImageUrl ?? 'https://via.placeholder.com/100',
                                ),
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                onBackgroundImageError: (_, __) {},
                                child: widget.event.creatorImageUrl == null
                                    ? Icon(Icons.person, size: 24, color: theme.colorScheme.primary)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Organized by',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.event.creatorName ?? 'Event Organizer',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to organizer profile
                                },
                                child: const Text('Profile'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Location Card - simplified without map
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.event.location ?? 'Location not specified',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // About this event - simplified
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'About this event',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.event.description ?? 'No description provided.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (widget.event.maxAttendees != null) ...[
                          const SizedBox(height: 16),
                          // Attendance Progress - simplified
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _reservationsCount >= widget.event.maxAttendees!
                                            ? Colors.red.withOpacity(0.1)
                                            : theme.colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.people_alt_rounded,
                                        size: 20,
                                        color: _reservationsCount >= widget.event.maxAttendees!
                                            ? Colors.red
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Attendance',
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '$_reservationsCount/${widget.event.maxAttendees} spots filled',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
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
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _reservationsCount >= widget.event.maxAttendees!
                                      ? 'This event is fully booked'
                                      : '${widget.event.maxAttendees! - _reservationsCount} spots remaining',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _reservationsCount >= widget.event.maxAttendees!
                                        ? Colors.red
                                        : Colors.green[700],
                                    fontWeight: _reservationsCount >= widget.event.maxAttendees!
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Spacer before bottom buttons - adjusted for smaller screens
                        SizedBox(height: size.height * 0.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      // Mobile-friendly floating action button
      floatingActionButton: _isLoading ? null : Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 48, // Fixed height
        width: size.width * 0.9, // Responsive width
        child: ElevatedButton.icon(
          icon: Icon(
            widget.event.paymentType == 'paid'
                ? Icons.shopping_cart_outlined
                : Icons.calendar_today_rounded,
            size: 18,
          ),
          label: Text(
            widget.event.paymentType == 'paid'
                ? 'Book for ${widget.event.ticketPrice} MAD'
                : 'Register for Free',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 2,
          ),
          onPressed: () {
            // Registration implementation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration feature coming soon!')),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Helper method for event tags - simplified
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10, // Smaller font size
        ),
      ),
    );
  }

  // Simplified stat item
  Widget _buildStatItem(IconData icon, String value, String label, ThemeData theme) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 18),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Simplified divider
  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[300],
    );
  }
}