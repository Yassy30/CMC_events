import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/SupabaseConfig.dart';
import '../models/comment.dart';

class CommentService {
  final _client = SupabaseConfig.client;

  Future<List<Comment>> getCommentsForEvent(String eventId) async {
    try {
      final response = await _client
          .from('comments')
          .select('*, users(username, profile_picture)')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return response.map<Comment>((data) {
        final userData = data['users'] as Map<String, dynamic>;
        return Comment(
          id: data['id'],
          eventId: data['event_id'],
          userId: data['user_id'],
          text: data['content'],
          createdAt: DateTime.parse(data['created_at']),
          username: userData['username'],
          userImageUrl: userData['profile_picture'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  Future<Comment?> addComment(String eventId, String userId, String text) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final newComment = {
        'event_id': eventId,
        'user_id': userId,
        'content': text,
        'created_at': timestamp,
      };

      final response = await _client
          .from('comments')
          .insert(newComment)
          .select('*, users(username, profile_picture)')
          .single();

      final userData = response['users'] as Map<String, dynamic>;
      return Comment(
        id: response['id'],
        eventId: response['event_id'],
        userId: response['user_id'],
        text: response['content'],
        createdAt: DateTime.parse(response['created_at']),
        username: userData['username'],
        userImageUrl: userData['profile_picture'],
      );
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }
}