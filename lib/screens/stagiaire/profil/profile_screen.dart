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
      print('Loading profile for userId: $userId');
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
          SnackBar(content: Text('Erreur de chargement du profil: $e')),
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
          SnackBar(content: Text('Erreur de chargement des événements: $e')),
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

  Future<void> _updateProfile() async {
    if (user != null) {
      setState(() {
        _isLoading = true;
      });
      final success = await _profileService.updateProfile(
        user!.id,
        _usernameController.text,
        _bioController.text,
        image: _image,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
        _loadUserProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la mise à jour du profil')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: user!,
          usernameController: _usernameController,
          bioController: _bioController,
          image: _image,
          onUpdate: _updateProfile,
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Confidentialité'),
                onTap: () {
                  Navigator.pop(context);
                  _showPrivacySettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.pop(context);
                  _showNotificationSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Langue'),
                onTap: () {
                  Navigator.pop(context);
                  _showLanguagePicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Partager le profil'),
                onTap: () {
                  Navigator.pop(context);
                  _shareProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer le compte', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteAccount();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres de confidentialité'),
        content: const Text('Ici, vous pouvez gérer qui peut voir votre profil et vos événements.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres de notifications'),
        content: const Text('Ici, vous pouvez activer/désactiver les notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une langue'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Français'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement language change logic
                },
              ),
              ListTile(
                title: const Text('English'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement language change logic
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareProfile() {
    final userId = _authService.getCurrentUser()?.id;
    if (userId != null) {
      Share.share('Découvrez mon profil sur IN\'CMC : https://app.incmc.com/profile/$userId');
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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
    final userId = _authService.getCurrentUser()?.id;
    if (userId != null) {
      setState(() {
        _isLoading = true;
      });
      final success = await _profileService.deleteAccount(userId);
      if (success && mounted) {
        await _authService.signOut();
        Navigator.pushReplacementNamed(context, '/auth');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la suppression du compte')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : (user!.profilePicture != null
                                      ? NetworkImage(user!.profilePicture!)
                                      : null),
                              child: user!.profilePicture == null && _image == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user!.username,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' ${user!.username.toLowerCase()}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user!.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            
                            children: [
                              _StatItem(
                                label: 'Événements',
                                value: createdEvents.length.toString(),
                              ),
                              const SizedBox(width: 16),
                              _StatItem(
                                label: 'Abonnés',
                                value: followCounts['followers'].toString(),
                              ),
                              const SizedBox(width: 16),
                              _StatItem(
                                label: 'Abonnements',
                                value: followCounts['following'].toString(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _navigateToEditProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Edit profile'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor:  AppTheme.lightTheme.colorScheme.primary,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor:  AppTheme.lightTheme.colorScheme.primary,

                      tabs: const [
                        Tab(text: 'Created'),
                        Tab(text: 'Saved'),
                      ],
                    ),
                    SizedBox(
                      height: 400, // Adjust based on screen size
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
    );
  }

  Widget _buildEventGrid(List<Map<String, dynamic>> events) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: event['image_url'] != null
              ? Image.network(
                  event['image_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.event),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                )
              : const Icon(Icons.event),
        );
      },
    );
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}