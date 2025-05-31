import 'package:cmc_ev/db/SupabaseConfig.dart';
import 'package:cmc_ev/models/user.dart' as local_user;
import 'package:cmc_ev/navigation/bottom_navigation.dart';
import 'package:cmc_ev/screens/admin/admin_dashboard.dart';
import 'package:cmc_ev/screens/stagiaire/autho/auth_screen.dart';
import 'package:cmc_ev/screens/stagiaire/profil/profile_screen.dart';
import 'package:cmc_ev/screens/stagiaire/splash_screen.dart';
import 'package:cmc_ev/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/screens/stagiaire/provider/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(const MyApp());
  print("Supabase initialized successfully");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
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
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }

    final user = await _fetchUser(session.user.id);
    if (user == null) {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }

    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).setUser(user);
      final route = user.role == 'admin' ? '/admin' : '/home';
      print('Initial navigation to $route for user: ${user.id}');
      Navigator.pushReplacementNamed(context, route);
    }
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

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}