import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/models/user.dart' as my_user;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

Future<AuthResponse?> signUp(String email, String password, String username, {String role = 'stagiaire'}) async {
  try {
    // Check if user already exists
    final existingUser = await _supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    if (existingUser != null) {
      print('User with email $email already exists');
      throw Exception('Email already in use');
    }

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'role': role},
    );
    if (response.user != null) {
      print('User created: id=${response.user!.id}, email=$email, role=$role');

      try {
        final insertResponse = await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'username': username,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('Insert response: $insertResponse');
      } catch (insertError) {
        print('Insert error: $insertError');
        rethrow;
      }

      print('User inserted: id=${response.user!.id}');
      if (response.session != null) {
        await _supabase.auth.setSession(response.session!.refreshToken!);
        print('Session set: user=${response.user!.id}');
      }
      return response;
    }
    print('Sign-up failed: No user returned');
    return null;
  } catch (e) {
    if (e.toString().contains('over_email_send_rate_limit')) {
      print('Sign-up error: Email send rate limit exceeded. Please wait 42 seconds and try again.');
      rethrow;
    }
    print('Sign-up error: $e');
    rethrow;
  }
}

Future<AuthResponse?> signIn(String email, String password) async {
  try {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    print('Sign-in successful: id=${response.user?.id}');

    // Check if user exists in users table, if not, insert
    final user = await getUserFromTable(response.user!.id);
    if (user == null) {
      print('User not found in users table, creating...');
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'username': response.user!.userMetadata?['username'] ?? 'default_user',
        'role': response.user!.userMetadata?['role'] ?? 'stagiaire',
        'created_at': DateTime.now().toIso8601String(),
      });
      print('User created in users table: id=${response.user!.id}');
    }

    return response;
  } catch (e) {
    print('Sign-in error: $e');
    rethrow;
  }
}

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    print('Signed out');
  }

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

  Future<my_user.User?> getUserFromTable(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      print('Fetched user: id=${response['id']}, role=${response['role']}');
      return my_user.User.fromMap(response);
    } catch (e) {
      print('Error fetching user from table: $e');
      return null;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}