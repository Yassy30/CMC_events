import 'dart:io';
import 'package:cmc_ev/screens/stagiaire/create_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cmc_ev/services/auth_service.dart';
import 'package:cmc_ev/services/profile_service.dart';
import 'package:cmc_ev/models/user.dart' as my_models;
import 'package:share_plus/share_plus.dart';
import 'edit_profile_screen.dart';
import 'package:cmc_ev/screens/stagiaire/profil/share_profile.dart';
import 'package:cmc_ev/screens/stagiaire/event_details_view.dart';
import 'package:cmc_ev/models/event.dart';
import 'package:intl/intl.dart';
import 'package:cmc_ev/services/event_service.dart';
import 'package:cmc_ev/services/like_service.dart';
import 'package:cmc_ev/services/comment_service.dart';
import 'package:cmc_ev/screens/stagiaire/event_details_full_page.dart' as event_details_full_page;
import 'package:cmc_ev/screens/stagiaire/home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Add optional userId parameter

  const ProfileScreen({super.key, this.userId});
  
  @override 
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  my_models.User? user;
  File? _image;
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  Map<String, int> followCounts = {'followers': 0, 'following': 0};
  List<Map<String, dynamic>> createdEvents = [];
  List<Map<String, dynamic>> savedEvents = [];
  bool _isLoading = false;
  late TabController _tabController;
  bool _isCurrentUser = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
    _loadEvents();
  }

  Future<void> _loadUserProfile() async {
    final currentUserId = _authService.getCurrentUser()?.id;
    final targetUserId = widget.userId ?? currentUserId;
    
    if (targetUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }

    setState(() {
      _isCurrentUser = targetUserId == currentUserId;
    });

    try {
      final profile = await _profileService.getUserProfile(targetUserId);
      final counts = await _profileService.getFollowCounts(targetUserId);
      bool isFollowing = false;
      if (!_isCurrentUser && currentUserId != null) {
        isFollowing = await _profileService.isFollowing(currentUserId, targetUserId);
      }
      
      if (profile != null && mounted) {
        setState(() {
          user = profile;
          _usernameController.text = profile.username;
          _bioController.text = profile.bio ?? '';
          followCounts = counts;
          _isFollowing = isFollowing;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil non trouvé')),
          );
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement du profil : $e')),
        );
      }
    }
  }

  Future<void> _loadEvents() async {
    final targetUserId = widget.userId ?? _authService.getCurrentUser()?.id;
    if (targetUserId == null) return;

    try {
      final created = await _profileService.getCreatedEvents(targetUserId);
      final saved = await _profileService.getSavedEvents(targetUserId);
      
      if (mounted) {
        setState(() {
          createdEvents = created;
          savedEvents = saved;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des événements : $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    if (!_isCurrentUser) return; // Only allow image picking for current user
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<bool> _updateProfile(String username, String bio, File? image) async {
    if (user != null && _isCurrentUser) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final imageUploadSuccess = await _profileService.updateProfile(
          user!.id,
          username,
          bio,
          image: image != null ? XFile(image.path) : null,
        );
        
        if (mounted) {
          await _loadUserProfile();
          setState(() {
            _image = null;
          });
          
          String message = 'Profil mis à jour avec succès';
          if (!imageUploadSuccess && image != null) {
            message = 'Nom d\'utilisateur et bio mis à jour, mais échec du téléchargement de l\'image';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: imageUploadSuccess ? null : Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return imageUploadSuccess;
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Erreur : $e';
          if (e.toString().contains('bucket')) {
            errorMessage = 'Problème avec le stockage des images. Veuillez contacter l\'administrateur.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        rethrow;
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
    return false;
  }

  Future<void> _toggleFollow() async {
    if (!_authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour suivre')),
      );
      return;
    }

    try {
      final currentUserId = _authService.getCurrentUser()?.id;
      if (currentUserId == null) return;

      await _profileService.followUser(currentUserId, widget.userId!, !_isFollowing);
      final counts = await _profileService.getFollowCounts(widget.userId!);

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          followCounts['followers'] = counts['followers']!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isFollowing ? 'Vous suivez maintenant' : 'Vous ne suivez plus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  void _navigateToEditProfile() {
    if (user != null && _isCurrentUser) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(
            user: user!,
            onUpdate: (String username, String bio, XFile? image) {
              return _updateProfile(
                username,
                bio,
                image != null ? File(image.path) : null,
              );
            },
          ),
        ),
      );
    }
  }

  void _showSettingsMenu() {
    if (!_isCurrentUser) return; // Only show settings for current user
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildSettingsItem(
              icon: Icons.share_rounded,
              title: 'Partager le profil',
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
            _buildSettingsItem(
              icon: Icons.edit_rounded,
              title: 'Modifier le profil',
              onTap: () {
                Navigator.pop(context);
                _navigateToEditProfile();
              },
            ),
            _buildSettingsItem(
              icon: Icons.delete_outline_rounded,
              title: 'Supprimer le compte',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteAccount();
              },
            ),
            _buildSettingsItem(
              icon: Icons.logout_rounded,
              title: 'Déconnexion',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _confirmSignOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.withOpacity(0.1) : Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareProfile() {
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShareProfileScreen(user: user!),
        ),
      );
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le compte'),
        content: const Text('Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _authService.getCurrentUser()?.id;
      if (userId != null) {
        await _profileService.deleteAccount(userId);
        await _authService.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression du compte : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la déconnexion : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isCurrentUser ? 'Profil' : user?.username ?? 'Profil',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        automaticallyImplyLeading: !_isCurrentUser, // false for current user, true for other users
        actions: _isCurrentUser
            ? [
                IconButton(
                  icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                  onPressed: _showSettingsMenu,
                ),
              ]
            : [],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: user == null
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _isCurrentUser ? (_isLoading ? null : _pickImage) : null,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: _image != null
                                ? FileImage(_image!)
                                : (user!.profilePicture != null
                                    ? NetworkImage(user!.profilePicture!)
                                    : null) as ImageProvider<Object>?,
                            child: user!.profilePicture == null && _image == null
                                ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                                : null,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          user!.username,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          '@${user!.username.toLowerCase()}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        if (user!.bio != null && user!.bio!.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            user!.bio!,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (!_isCurrentUser) ...[
                          SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _toggleFollow,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            ),
                            child: Text(
                              _isFollowing ? 'Unfollow' : 'Follow',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatItem(
                              label: 'Événements',
                              value: createdEvents.length.toString(),
                            ),
                            SizedBox(width: 24),
                            _StatItem(
                              label: 'Abonnés',
                              value: followCounts['followers'].toString(),
                            ),
                            SizedBox(width: 24),
                            _StatItem(
                              label: 'Abonnements',
                              value: followCounts['following'].toString(),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          tabs: [
                            Tab(text: 'Créés'),
                            Tab(text: 'Enregistrés'),
                          ],
                        ),
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildEventList(createdEvents),
                              _buildEventList(savedEvents),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> events) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final eventMap = events[index];
        final event = Event.fromJson(eventMap);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProfileEventCard(event: event),
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}

class ProfileEventCard extends StatefulWidget {
  final Event event;

  const ProfileEventCard({super.key, required this.event});

  @override 
  State<ProfileEventCard> createState() => _ProfileEventCardState();
} 

class _ProfileEventCardState extends State<ProfileEventCard> {
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
    final scrollController = ScrollController();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => event_details_full_page.EventDetailsFullPage(
          event: widget.event,
          controller: scrollController,
        ),
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
        GestureDetector(
          onTap: () => _showEventDetails(context),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 8,
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
              Row(
                children: [
                  _buildSocialAction(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    text: '$_likesCount',
                    onTap: _toggleLike,
                    isActive: _isLiked,
                    color: _isLiked ? Colors.red : Colors.grey[600],
                  ),
                  SizedBox(width: 12),
                  _buildSocialAction(
                    icon: Icons.chat_bubble_outline,
                    text: '$_commentsCount',
                    onTap: () => _showComments(context),
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 12),
                  _buildSocialAction(
                    icon: Icons.share_outlined,
                    text: 'Share',
                    onTap: () => _shareEvent(context),
                    color: Colors.grey[600],
                  ),
                  Spacer(),
                  OutlinedButton(
                    onPressed: () => _showEventDetails(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: Size(0, 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: theme.colorScheme.primary, width: 1),
                    ),
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8), // Add spacing between buttons
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateEventScreen(
                            // event: widget.event, // Pass the event for editing
                          ),
                        
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: Size(0, 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: theme.colorScheme.primary, width: 1),
                    ),
                    child: Text(
                      'Modifier',
                      style: TextStyle(
                        fontSize: 10,
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
              size: 14,
              color: color,
            ),
            SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}