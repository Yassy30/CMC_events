import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/models/user.dart' as my_user;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
 User? get currentUser => _supabase.auth.currentUser;
  String get currentUserId => currentUser?.id ?? '';
  bool get isLoggedIn => currentUser != null;
    Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

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
// Add this method to your AuthService class
// Replace the existing sendPasswordResetOTP method with this:

Future<void> sendPasswordResetEmail(String email) async {
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

    // Send password reset email using Supabase Auth
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'yourapp://reset-password', // Replace with your app's deep link
    );

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

// Implement actual email sending
Future<void> _sendOTPEmail(String email, String otp) async {
  try {
    // Example using http package to call your email service
    // You need to implement your own email service endpoint
    
    final response = await http.post(
      Uri.parse('YOUR_EMAIL_SERVICE_ENDPOINT'), // Replace with your endpoint
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_API_KEY', // Your email service API key
      },
      body: jsonEncode({
        'to': email,
        'subject': 'Password Reset Code',
        'html': '''
          <h2>Password Reset</h2>
          <p>Your password reset code is: <strong>$otp</strong></p>
          <p>This code will expire in 3 minutes.</p>
        ''',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send email: ${response.body}');
    }
    
    print('OTP email sent successfully to $email');
  } catch (e) {
    print('Email sending error: $e');
    throw Exception('Failed to send verification email. Please try again.');
  }
}
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

    // Generate OTP
    final otp = _generateOTP();
    
    // Store OTP in database
    await _supabase.from('password_reset_otps').insert({
      'email': email,
      'otp': otp,
      'expires_at': DateTime.now().add(const Duration(minutes: 3)).toIso8601String(),
      'used': false,
    });

    // Send OTP via email
    await _sendOTPEmail(email, otp);

    print('Password reset OTP sent to: $email');
  } catch (e) {
    print('Send password reset OTP error: $e');
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

  
}