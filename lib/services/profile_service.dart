import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/models/user.dart' as local_user;

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
 
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
      print('Error fetching profile: $e');
      return null;
    }
  }

  // Update profile
  Future<bool> updateProfile(String userId, String username, String? bio,
      {File? image}) async {
    try {
      final updates = {'username': username, 'bio': bio};
      if (image != null) {
        final imageUrl = await _uploadProfileImage(userId, image);
        updates['profile_picture'] = imageUrl;
      }
      await _supabase.from('users').update(updates).eq('id', userId);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Upload profile image
  Future<String> _uploadProfileImage(String userId, File image) async {
  final path = 'profile-pictures/$userId.jpg';
  await _supabase.storage.from('profile-pictures').upload(path, image);
  return _supabase.storage.from('profile-pictures').getPublicUrl(path);
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
      print('Error following/unfollowing: $e');
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
      print('Error fetching follow counts: $e');
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
      print('Error fetching created events: $e');
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
    // Ensure the response is a List of Maps with String keys
    return (response as List).map((row) {
      final event = row['events'] as Map? ?? {};
      return event.cast<String, dynamic>();
    }).toList();
  } catch (e) {
    print('Error fetching saved events: $e');
    return [];
  }
}
}