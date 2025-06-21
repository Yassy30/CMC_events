import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/SupabaseConfig.dart';
import '../models/like.dart';

class LikeService {
  final _client = SupabaseConfig.client;

  Future<int> getLikesCount(String eventId) async {
    try {
      print('Getting likes count for event: $eventId');
      // Use the correct count approach for your Supabase version
      final response = await _client
          .from('likes')
          .select()
          .eq('event_id', eventId);
      
      print('Likes response: ${response.length} likes found');
      // Count manually if count() is not available
      return response.length;
    } catch (e, stackTrace) {
      print('Error getting likes count: $e');
      print('Stack trace: $stackTrace');
      return 0;
    }
  }

  Future<bool> isEventLikedByUser(String eventId, String userId) async {
    if (userId.isEmpty) {
      print('Warning: Empty userId provided to isEventLikedByUser');
      return false;
    }
    
    try {
      print('Checking if event $eventId is liked by user $userId');
      final response = await _client
          .from('likes')
          .select('id') // Only select the ID to minimize data transfer
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();
      
      final isLiked = response != null;
      print('Event $eventId liked by user $userId: $isLiked');
      return isLiked;
    } catch (e, stackTrace) {
      print('Error checking if event is liked: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> toggleLike(String eventId, String userId) async {
    if (userId.isEmpty) {
      print('Warning: Empty userId provided to toggleLike');
      throw Exception('User ID cannot be empty');
    }
    
    try {
      print('Toggling like for event $eventId by user $userId');
      final isLiked = await isEventLikedByUser(eventId, userId);
      
      if (isLiked) {
        // Remove like
        print('Removing like for event $eventId by user $userId');
        await _client
            .from('likes')
            .delete()
            .eq('event_id', eventId)
            .eq('user_id', userId);
        print('Like removed successfully');
        return false;
      } else {
        // Add like
        print('Adding like for event $eventId by user $userId');
        final timestamp = DateTime.now().toIso8601String();
        await _client
            .from('likes')
            .insert({
              'event_id': eventId,
              'user_id': userId,
              'created_at': timestamp,
            });
        print('Like added successfully');
        return true;
      }
    } catch (e, stackTrace) {
      print('Error toggling like: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to toggle like status: $e');
    }
  }

  // Add this method to your LikeService class
  Future<bool> checkIfLiked(String eventId, String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('likes')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .limit(1);
    
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking if event is liked: $e');
      return false;
    }
  }
}