import 'package:cmc_ev/navigation/bottom_navigation.dart';
import 'package:cmc_ev/screens/admin/admin_dashboard.dart';
import 'package:cmc_ev/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:cmc_ev/screens/splash_screen.dart';
import 'package:cmc_ev/screens/home_screen.dart';
import 'package:cmc_ev/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
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
