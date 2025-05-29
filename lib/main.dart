import 'package:cmc_ev/db/SupabaseConfig.dart';
import 'package:cmc_ev/models/user.dart' as local_user;
import 'package:cmc_ev/navigation/bottom_navigation.dart';
import 'package:cmc_ev/screens/admin/admin_dashboard.dart';
import 'package:cmc_ev/screens/stagiaire/auth_screen.dart';
import 'package:cmc_ev/screens/stagiaire/home_screen.dart';
import 'package:cmc_ev/screens/stagiaire/profile_screen.dart';
import 'package:cmc_ev/screens/stagiaire/splash_screen.dart';
import 'package:cmc_ev/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
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
          final session = snapshot.data?.session;
          if (session == null) {
            return const AuthScreen();
          }
          // Fetch user role to determine routing
          return FutureBuilder<local_user.User?>(
            future: _fetchUser(session.user.id),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              final user = userSnapshot.data;
              if (user != null) {
                Provider.of<UserProvider>(context, listen: false).setUser(user);
                if (user.role == 'admin') {
                  return const AdminDashboard();
                }
                return const MainNavigation();
              }
              return const AuthScreen();
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

class UserProvider with ChangeNotifier {
  local_user.User? _user;
  local_user.User? get user => _user;

  void setUser(local_user.User user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}