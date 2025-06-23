import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cmc_ev/models/user.dart' as my_models;
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final my_models.User user;
final Function(String, String, XFile?) onUpdate; // Ensure XFile? is used  
  const EditProfileScreen({
    super.key,
    required this.user,
    required this.onUpdate,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  XFile? _image; // Change from File to XFile
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _image = null;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _image = pickedFile; // Store XFile
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom d\'utilisateur ne peut pas être vide')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUploadSuccess = await widget.onUpdate(
        _usernameController.text,
        _bioController.text,
        _image, // Pass XFile? directly
      );

      if (mounted) {
        String message = 'Profil mis à jour avec succès';
        if (!imageUploadSuccess && _image != null) {
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
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la mise à jour : $e';
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
          'Modifier le Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[50],
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Profile Picture
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _image != null
                            ? null
                            : (widget.user.profilePicture != null
                                ? NetworkImage(widget.user.profilePicture!)
                                : null) as ImageProvider<Object>?,
                        child: _image != null
                            ? FutureBuilder<Uint8List>(
                                future: _image!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                    return ClipOval(
                                      child: Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      ),
                                    );
                                  } else if (snapshot.hasError) {
                                    return const Icon(Icons.error, size: 60, color: Colors.red);
                                  } else {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                },
                              )
                            : (_image == null && widget.user.profilePicture == null
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                Text(
                  'Changer la photo de profil',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Username Field
                _buildTextField(
                  controller: _usernameController,
                  label: 'Nom d\'utilisateur',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom d\'utilisateur';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Bio Field
                _buildTextField(
                  controller: _bioController,
                  label: 'Bio',
                  icon: Icons.info,
                  maxLines: 3,
                ),
                
                const SizedBox(height: 40),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}