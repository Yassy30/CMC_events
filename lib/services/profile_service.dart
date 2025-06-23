import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/models/user.dart' as local_user;
import 'dart:io' if (dart.library.html) 'dart:html'; // Conditional import for web

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'profile-pictures';

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

Future<bool> updateProfile(
    String userId,
    String username,
    String bio, {
    XFile? image,
  }) async {
    try {
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
        try {
          // Debug: Log XFile properties
          print('Image name: ${image.name}, Size: ${await image.length()}');

          // Read bytes from XFile
          final bytes = await image.readAsBytes();

          // Determine file extension
          String extension = '';
          if (image.name.contains('.')) {
            extension = image.name.split('.').last.toLowerCase();
          } else {
            // Fallback: Try to infer from MIME type
            final mimeType = image.mimeType ?? 'image/jpeg'; // Default to jpeg if unknown
            extension = mimeType.split('/').last.toLowerCase();
          }

          // Support more formats
          const supportedFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'];
          if (!supportedFormats.contains(extension)) {
            throw Exception('Format d\'image non supporté : $extension');
          }

          // Ensure valid content type
          final contentType = extension == 'heic' || extension == 'heif'
              ? 'image/heic' // HEIC/HEIF may need special handling
              : 'image/$extension';

          final imagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

          await _supabase.storage.from(_bucketName).uploadBinary(
                imagePath,
                bytes,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: contentType,
                ),
              );

          final imageUrl = _supabase.storage.from(_bucketName).getPublicUrl(imagePath);
          updates['profile_picture'] = imageUrl;
        } catch (e) {
          imageUploadSuccess = false;
          print('Erreur lors du téléchargement de l\'image : $e');
          // Continue with profile update even if image upload fails
        }
      }

      await _supabase.from('users').update(updates).eq('id', userId);
      return imageUploadSuccess;
    } catch (e) {
      print('Erreur lors de la mise à jour du profil : $e');
      rethrow;
    }
  }

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

   Future<void> unfollowUser(String followerId, String followedId) async {
    try {
      await _supabase
          .from('followers')
          .delete()
          .eq('follower_id', followerId)
          .eq('followed_id', followedId);
    } catch (e) {
      print('Error unfollowing user: $e');
      throw Exception('Failed to unfollow user');
    }
  }

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

  Future<List<Map<String, dynamic>>> getCreatedEvents(String userId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('*, users!events_creator_id_fkey(username, profile_picture)')
          .eq('creator_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response).map((event) {
        return {
          ...event,
          'creatorName': event['users']?['username'] ?? 'Unknown',
          'creatorImageUrl': event['users']?['profile_picture'],
        };
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des événements créés : $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSavedEvents(String userId) async {
    try {
      final response = await _supabase
          .from('saved_events')
          .select('events(*, users!events_creator_id_fkey(username, profile_picture))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map<Map<String, dynamic>>((row) {
            final event = (row['events'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
            return {
              ...event,
              'creatorName': event['users']?['username'] ?? 'Unknown',
              'creatorImageUrl': event['users']?['profile_picture'],
            };
          })
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des événements enregistrés : $e');
      return [];
    }
  }

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

  Future<bool> isFollowing(String followerId, String followedId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', followerId)
          .eq('followed_id', followedId);
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  Future<void> toggleSaveEvent(String eventId, String userId) async {
    try {
      final isSaved = await isEventSaved(eventId, userId);
      if (isSaved) {
        await _supabase
            .from('saved_events')
            .delete()
            .eq('event_id', eventId)
            .eq('user_id', userId);
      } else {
        await _supabase.from('saved_events').insert({
          'event_id': eventId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error toggling save event: $e');
      rethrow;
    }
  }

  Future<bool> isEventSaved(String eventId, String userId) async {
    try {
      final response = await _supabase
          .from('saved_events')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking save status: $e');
      return false;
    }
  }
}