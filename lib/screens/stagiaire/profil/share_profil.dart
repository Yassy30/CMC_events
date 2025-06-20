import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cmc_ev/models/user.dart' as my_models;

class ShareProfileScreen extends StatefulWidget {
  final my_models.User user;
  
  const ShareProfileScreen({
    super.key,
    required this.user,
  });

  @override
  _ShareProfileScreenState createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends State<ShareProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String get profileUrl => 'https://app.incmc.com/profile/${widget.user.id}';
  String get shareText => 'Découvrez mon profil sur IN\'CMC : $profileUrl';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  void _shareProfile() {
    Share.share(shareText);
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: profileUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Lien copié dans le presse-papiers'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _shareViaWhatsApp() {
    Share.share(shareText, subject: 'Mon profil IN\'CMC');
  }

  void _shareViaEmail() {
    Share.share(
      shareText,
      subject: 'Découvrez mon profil sur IN\'CMC',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Partager le Profil',
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
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Profile Preview Card
                  _buildProfilePreviewCard(),
                  
                  const SizedBox(height: 30),
                  
                  // QR Code Section
                  _buildQRCodeSection(),
                  
                  const SizedBox(height: 30),
                  
                  // Share Options
                  _buildShareOptions(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Votre profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Profile Picture
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: widget.user.profilePicture != null
                ? NetworkImage(widget.user.profilePicture!)
                : null,
            child: widget.user.profilePicture == null
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          
          const SizedBox(height: 15),
          
          // Username
          Text(
            widget.user.username,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Handle
          Text(
            '@${widget.user.username.toLowerCase()}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          // Bio
          if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.user.bio!,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Code QR de votre profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: QrImageView(
              data: profileUrl,
              size: 180,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          
          const SizedBox(height: 15),
          Text(
            'Scannez ce code pour accéder au profil',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShareOptions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Options de partage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          
          // General Share
          _buildShareOption(
            icon: Icons.share,
            title: 'Partager',
            subtitle: 'Partager via toutes les applications',
            onTap: _shareProfile,
          ),
          
          const SizedBox(height: 15),
          
          // Copy Link
          _buildShareOption(
            icon: Icons.link,
            title: 'Copier le lien',
            subtitle: 'Copier l\'URL du profil',
            onTap: _copyLink,
          ),
          
          const SizedBox(height: 15),
          
          // WhatsApp
          _buildShareOption(
            icon: Icons.message,
            title: 'WhatsApp',
            subtitle: 'Partager via WhatsApp',
            onTap: _shareViaWhatsApp,
          ),
          
          const SizedBox(height: 15),
          
          // Email
          _buildShareOption(
            icon: Icons.email,
            title: 'Email',
            subtitle: 'Envoyer par email',
            onTap: _shareViaEmail,
          ),
          
          const SizedBox(height: 20),
          
          // Profile URL Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    profileUrl,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _copyLink,
                  icon: Icon(
                    Icons.copy,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}