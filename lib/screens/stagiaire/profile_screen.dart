import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/services/auth_service.dart';
// import 'package:cmc_ev/services/';
import 'package:cmc_ev/services/profile_service.dart';
import 'package:cmc_ev/models/user.dart' as my_models;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
 
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'utilisateur',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Mettre à jour le profil'),
                ),
                const SizedBox(height: 24),
                _buildStatRow(),
                const Divider(height: 32),
                _buildSection('Mes événements'),
                _buildSection('Événements sauvegardés'),
              ],
            ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(
          label: 'Événements',
          value: createdEvents.length.toString(),
        ),
        _StatItem(
          label: 'Abonnés',
          value: followCounts['followers'].toString(),
        ),
        _StatItem(
          label: 'Abonnements',
          value: followCounts['following'].toString(),
        ),
      ],
    );
  }

  Widget _buildSection(String title) {
    final isCreatedEvents = title == 'Mes événements';
    final events = isCreatedEvents ? createdEvents : savedEvents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        events.isEmpty
            ? const Center(child: Text('Aucun événement'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    leading: event['image_url'] != null
                        ? Image.network(
                            event['image_url'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.event),
                          )
                        : const Icon(Icons.event),
                    title: Text(event['title']),
                    subtitle: Text(
                      '${event['start_date'].toString().substring(0, 10)} - ${event['location'] ?? 'Aucun lieu'}',
                    ),
                    onTap: () {
                      // TODO: Navigate to event details
                    },
                  );
                },
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}