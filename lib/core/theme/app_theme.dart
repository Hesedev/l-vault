// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF121212);
  static const Color navBar = Color(0xFF1E1E1E);
  static const Color dialog = Color(0xFF282828);
  static const Color input = Color(0xFF404040);
  static const Color hint = Color(0xFF909090);
  static const Color text = Color(0xFFFFFFFF);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    scaffoldBackgroundColor: background,

    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      surface: Color(0xFF282828),
      onSurface: text,
    ),

    cardTheme: const CardThemeData(color: Color(0xFF282828)),

    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      foregroundColor: text,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: navBar,
      selectedItemColor: Colors.blue,
      unselectedItemColor: hint,
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: dialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: input,

      hintStyle: const TextStyle(color: hint),

      labelStyle: const TextStyle(color: hint),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.blue),
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: text),
      bodyMedium: TextStyle(color: text),
      titleLarge: TextStyle(color: text),
      titleMedium: TextStyle(color: text),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppTheme.dialog,
      modalBackgroundColor: AppTheme.dialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}
