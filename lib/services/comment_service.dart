import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/SupabaseConfig.dart';
import '../models/comment.dart';


class CommentService {
  final _client = SupabaseConfig.client;

  Future<List<Comment>> getCommentsForEvent(String eventId) async {
    try {
      final response = await _client
          .from('Comment')
          .select('*, User!Comment_user_id_fkey(username, profile_picture)')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return response.map<Comment>((data) {
        final userData = data['User'] as Map<String, dynamic>? ?? {};
        return Comment(
          id: data['id'] as String,
          eventId: data['event_id'] as String,
          userId: data['user_id'] as String,
          text: data['content'] as String,
          createdAt: DateTime.parse(data['created_at'] as String),
          username: userData['username'] as String? ?? 'Unknown',
          userImageUrl: userData['profile_picture'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  Future<Comment?> addComment(
      String eventId, String userId, String text) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final newComment = {
        'event_id': eventId,
        'user_id': userId,
        'content': text,
        'created_at': timestamp,
      };

      final response = await _client
          .from('Comment')
          .insert(newComment)
          .select('*, User!Comment_user_id_fkey(username, profile_picture)')
          .single();

      final userData = response['User'] as Map<String, dynamic>? ?? {};
      return Comment(
        id: response['id'] as String,
        eventId: response['event_id'] as String,
        userId: response['user_id'] as String,
        text: response['content'] as String,
        createdAt: DateTime.parse(response['created_at'] as String),
        username: userData['username'] as String? ?? 'Unknown',
        userImageUrl: userData['profile_picture'] as String?,
      );
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  Future<int> getCommentsCount(String eventId) async {
    try {
      final response = await SupabaseConfig.client
          .from('comments')
          .select()
          .eq('event_id', eventId);

      return response.length;
    } catch (e) {
      print('Error getting comments count: $e');
      return 0;
    }
  }
}