import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/models/user.dart' as my_user;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up with email, password, and username
  Future<AuthResponse?> signUp(
      String email, String password, String username) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'role': 'stagiaire'},
      );

      // Insert user details into the users table
      if (response.user != null) {
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'username': username,
          'role': 'stagiaire',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return response;
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<AuthResponse?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user
  my_user.User? getCurrentUser() {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;
    return my_user.User(
      id: authUser.id,
      email: authUser.email ?? '',
      username: authUser.userMetadata?['username'] ?? '',
      role: authUser.userMetadata?['role'] ?? 'stagiaire',
    );
  }

  // Stream for auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
