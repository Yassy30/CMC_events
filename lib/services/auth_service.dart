import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/models/user.dart' as my_user;
import 'dart:math';
import 'package:http/http.dart' as http;

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

  // NEW: Generate 6-digit OTP
  String _generateOTP() {
    final random = Random();
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  // NEW: Send OTP for password reset
 Future<void> sendPasswordResetOTP(String email) async {
  try {
    // Check if user exists
    final userExists = await _supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    
    if (userExists == null) {
      throw Exception('No account found with this email address');
    }

    // Trigger Supabase Auth's password reset email
    await _supabase.auth.resetPasswordForEmail(email, redirectTo: 'yourapp://reset-password');

    print('Password reset email sent to: $email');
  } catch (e) {
    print('Send password reset error: $e');
    rethrow;
  }
}
  // NEW: Verify OTP
  Future<bool> verifyPasswordResetOTP(String email, String enteredOTP) async {
    try {
      // Get the latest OTP for this email
      final otpRecord = await _supabase
          .from('password_reset_otps')
          .select()
          .eq('email', email)
          .eq('used', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (otpRecord == null) {
        throw Exception('No valid OTP found for this email');
      }

      // Check if OTP has expired
      final expiresAt = DateTime.parse(otpRecord['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('OTP has expired. Please request a new one.');
      }

      // Check if OTP matches
      if (otpRecord['otp'] != enteredOTP) {
        throw Exception('Invalid OTP. Please check and try again.');
      }

      // Mark OTP as used
      await _supabase
          .from('password_reset_otps')
          .update({'used': true})
          .eq('id', otpRecord['id']);

      print('OTP verified successfully for: $email');
      return true;
    } catch (e) {
      print('Verify OTP error: $e');
      rethrow;
    }
  }
// NEW: Update user's password
  Future<void> updatePassword(String newPassword) async {
    try {
      // Ensure the user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in.');
      }

      // Update the password using Supabase Auth
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      print('Password updated successfully for user: ${currentUser.email}');
    } catch (e) {
      print('Update password error: $e');
      rethrow;
    }
  }
  // NEW: Reset password after OTP verification
Future<void> resetPasswordWithOTP(String email, String newPassword) async {
  try {
    // Update the user's password
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    print('Password reset completed for: $email');
  } catch (e) {
    print('Reset password error: $e');
    rethrow;
  }
}

  // Helper method to send OTP email
  Future<void> _sendOTPEmail(String email, String otp) async {
    // This is a placeholder - you'll need to implement actual email sending
    // Options:
    // 1. Supabase Edge Functions with Resend/SendGrid
    // 2. Firebase Functions
    // 3. Your own backend API
    
    print('📧 Sending OTP email to $email: $otp');
    
    // For now, we'll simulate email sending
    // In production, integrate with email service
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