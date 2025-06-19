import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/models/user.dart' as local_user;

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'profile-pictures'; // Updated to match existing bucket

  // Fetch user profile
  Future<local_user.User?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return local_user.User.fromMap(response);
    } catch (e) {
      print('Erreur lors de la récupération du profil : $e');
      rethrow;
    }
  }

  // Update profile
  Future<bool> updateProfile(
    String userId,
    String username,
    String bio, {
    File? image,
  }) async {
    try {
      // Validate inputs
      if (username.isEmpty) {
        throw Exception('Le nom d\'utilisateur ne peut pas être vide');
      }

      final updates = {
        'username': username,
        'bio': bio,
        'updated_at': DateTime.now().toIso8601String(),
      };

      bool imageUploadSuccess = true;
      if (image != null) {
        // Validate image file
        if (!await image.exists()) {
          throw Exception('Le fichier image n\'existe pas');
        }
        final imagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        try {
          await _supabase.storage.from(_bucketName).upload(
                imagePath,
                image,
                fileOptions: const FileOptions(upsert: true),
              );
          final imageUrl = _supabase.storage.from(_bucketName).getPublicUrl(imagePath);
          updates['profile_picture'] = imageUrl;
        } catch (e) {
          imageUploadSuccess = false;
          print('Erreur lors du téléchargement de l\'image : $e');
          // Continue with username and bio update despite image failure
        }
      }

      await _supabase.from('users').update(updates).eq('id', userId);
      return imageUploadSuccess; // Return false if image upload failed, true otherwise
    } catch (e) {
      print('Erreur lors de la mise à jour du profil : $e');
      rethrow;
    }
  }

  // Follow/Unfollow user
  Future<void> followUser(String followerId, String followedId, bool follow) async {
    try {
      if (follow) {
        await _supabase.from('follows').insert({
          'follower_id': followerId,
          'followed_id': followedId,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', followerId)
            .eq('followed_id', followedId);
      }
    } catch (e) {
      print('Erreur lors du suivi/désabonnement : $e');
    }
  }

  // Get follower and following counts
  Future<Map<String, int>> getFollowCounts(String userId) async {
    try {
      final followers = await _supabase
          .from('follows')
          .select()
          .eq('followed_id', userId)
          .count();
      final following = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', userId)
          .count();
      return {
        'followers': followers.count,
        'following': following.count,
      };
    } catch (e) {
      print('Erreur lors de la récupération des compteurs de suivi : $e');
      return {'followers': 0, 'following': 0};
    }
  }

  // Fetch created events
  Future<List<Map<String, dynamic>>> getCreatedEvents(String userId) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('creator_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des événements créés : $e');
      return [];
    }
  }

  // Fetch saved events
  Future<List<Map<String, dynamic>>> getSavedEvents(String userId) async {
    try {
      final response = await _supabase
          .from('saved_events')
          .select('events(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((row) {
        final event = row['events'] as Map? ?? {};
        return event.cast<String, dynamic>();
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des événements enregistrés : $e');
      return [];
    }
  }

  // Delete account
  Future<bool> deleteAccount(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
      await _supabase.auth.admin.deleteUser(userId);
      return true;
    } catch (e) {
      print('Erreur lors de la suppression du compte : $e');
      return false;
    }
  }
}