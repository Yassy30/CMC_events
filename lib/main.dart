import 'package:cmc_ev/navigation/bottom_navigation.dart';
import 'package:cmc_ev/screens/admin/admin_dashboard.dart';
import 'package:cmc_ev/screens/stagiaire/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:cmc_ev/screens/stagiaire/splash_screen.dart';
import 'package:cmc_ev/screens/stagiaire/home_screen.dart';
import 'package:cmc_ev/theme/app_theme.dart';
import 'package:cmc_ev/db/SupabaseConfig.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  // hello 
  // Initialize the Supabase client

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
      home: const SplashScreen(),
    );
  }
}
