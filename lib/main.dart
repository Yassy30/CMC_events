import 'package:cmc_ev/db/SupabaseConfig.dart';
import 'package:cmc_ev/models/user.dart' as local_user;
import 'package:cmc_ev/navigation/bottom_navigation.dart';
import 'package:cmc_ev/screens/admin/admin_dashboard.dart';
import 'package:cmc_ev/screens/stagiaire/autho/auth_screen.dart';
import 'package:cmc_ev/screens/stagiaire/home_screen.dart';
import 'package:cmc_ev/screens/stagiaire/profil/profile_screen.dart';
import 'package:cmc_ev/screens/stagiaire/splash_screen.dart';
import 'package:cmc_ev/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/screens/stagiaire/provider/user_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:cmc_ev/db/SupabaseConfig.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(const MyApp());
  print("Supabase initialized successfully");
  // You can now use SupabaseConfig.client to access the Supabase client
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IN\'CMC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const MainNavigation(),
        '/profile': (context) => const ProfileScreen(),
        '/admin': (context) => const AdminDashboard(),
      },
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          return FutureBuilder<void>(
            future: Future.delayed(const Duration(seconds: 2)),
            builder: (context, delaySnapshot) {
              if (delaySnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              final session = snapshot.data?.session;
              if (session == null) {
                return const AuthScreen();
              }
              return FutureBuilder<local_user.User?>(
                future: _fetchUser(session.user.id),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const SplashScreen();
                  }
                  if (userSnapshot.hasError || userSnapshot.data == null) {
                    print('User fetch error or null: ${userSnapshot.error}');
                    Supabase.instance.client.auth.signOut();
                    return const AuthScreen();
                  }
                  final user = userSnapshot.data!;
                  // Set user outside build phase
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<UserProvider>(context, listen: false).setUser(user);
                  });
                  print('Initial navigation to ${user.role == 'admin' ? '/admin' : '/home'} for user: ${user.id}');
                  return user.role == 'admin' ? const AdminDashboard() : const MainNavigation();
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<local_user.User?> _fetchUser(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return local_user.User.fromMap(response);
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }
}