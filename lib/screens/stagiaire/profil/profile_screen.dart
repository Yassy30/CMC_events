import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/services/auth_service.dart';
import 'package:cmc_ev/services/profile_service.dart';
import 'package:cmc_ev/models/user.dart' as my_models;
import 'package:share_plus/share_plus.dart';
import 'edit_profile_screen.dart';
import 'package:cmc_ev/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
    _loadEvents();
  }

  Future<void> _loadUserProfile() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }
    try {
      final profile = await _profileService.getUserProfile(userId);
      final counts = await _profileService.getFollowCounts(userId);
      if (profile != null && mounted) {
        setState(() {
          user = profile;
          _usernameController.text = profile.username;
          _bioController.text = profile.bio ?? '';
          followCounts = counts;
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
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) return;
    try {
      final created = await _profileService.getCreatedEvents(userId);
      final saved = await _profileService.getSavedEvents(userId);
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
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<bool> _updateProfile(String username, String bio, File? image) async {
    if (user != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        final imageUploadSuccess = await _profileService.updateProfile(
          user!.id,
          username,
          bio,
          image: image,
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

  void _navigateToEditProfile() {
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(
            user: user!,
            onUpdate: _updateProfile,
          ),
        ),
      );
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
            title: Text('Partager le profil'),
            onTap: () {
              Navigator.pop(context);
              _shareProfile();
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmSignOut();
            },
          ),
        ],
      ),
    );
  }

  void _shareProfile() {
    final userId = _authService.getCurrentUser()?.id;
    if (userId != null) {
      Share.share('Découvrez mon profil sur IN\'CMC : https://app.incmc.com/profile/$userId');
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            child: Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
        title: Text('Profil', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
            onPressed: _showSettingsMenu,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6F0FA).withOpacity(0.8), // Light blue gradient
              Color(0xFFB3E5FC).withOpacity(0.8),
            ],
          ),
        ),
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
                          onTap: _isLoading ? null : _pickImage,
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
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _navigateToEditProfile,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Modifier le profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                          height: 300,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildEventGrid(createdEvents),
                              _buildEventGrid(savedEvents),
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

  Widget _buildEventGrid(List<Map<String, dynamic>> events) {
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: event['image_url'] != null
              ? Image.network(
                  event['image_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.event,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                )
              : Icon(
                  Icons.event,
                  size: 40,
                  color: Colors.grey[400],
                ),
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