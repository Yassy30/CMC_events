import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor:  Color.fromARGB(255, 126, 166, 176),
      primary:  Color(0xFF37A2BC),
      secondary:  Color.fromARGB(255, 6, 144, 178),
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );

  static var primaryColor = const Color(0xFF37A2BC);
}