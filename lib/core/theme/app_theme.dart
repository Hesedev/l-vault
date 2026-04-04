// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // ── Dark theme colors ──────────────────────────────────────────────────────
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkNavBar = Color(0xFF1E1E1E);
  static const Color _darkDialog = Color(0xFF282828);
  static const Color _darkInput = Color(0xFF404040);
  static const Color _darkHint = Color(0xFF909090);
  static const Color _darkText = Color(0xFFFFFFFF);

  // ── Light theme colors ─────────────────────────────────────────────────────
  static const Color _lightBackground = Color(0xFFF5F5F5);
  static const Color _lightNavBar = Color(0xFFFFFFFF);
  static const Color _lightDialog = Color(0xFFFFFFFF);
  static const Color _lightInput = Color(0xFFEEEEEE);
  static const Color _lightHint = Color(0xFF888888);
  static const Color _lightText = Color(0xFF121212);

  // Keep exposed for use in other files (e.g. AppShell)
  static const Color darkNavBar = _darkNavBar;
  static const Color lightNavBar = _lightNavBar;
  static const Color darkDialog = _darkDialog;
  static const Color lightDialog = _lightDialog;

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      surface: _darkDialog,
      onSurface: _darkText,
    ),
    cardTheme: const CardThemeData(color: _darkDialog),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      elevation: 0,
      foregroundColor: _darkText,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkNavBar,
      selectedItemColor: Colors.blue,
      unselectedItemColor: _darkHint,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: _darkDialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkInput,
      hintStyle: const TextStyle(color: _darkHint),
      labelStyle: const TextStyle(color: _darkHint),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _darkText),
      bodyMedium: TextStyle(color: _darkText),
      titleLarge: TextStyle(color: _darkText),
      titleMedium: TextStyle(color: _darkText),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _darkDialog,
      modalBackgroundColor: _darkDialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBackground,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      surface: _lightDialog,
      onSurface: _lightText,
    ),
    cardTheme: const CardThemeData(color: _lightDialog),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackground,
      elevation: 0,
      foregroundColor: _lightText,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _lightNavBar,
      selectedItemColor: Colors.blue,
      unselectedItemColor: _lightHint,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: _lightDialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightInput,
      hintStyle: const TextStyle(color: _lightHint),
      labelStyle: const TextStyle(color: _lightHint),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _lightText),
      bodyMedium: TextStyle(color: _lightText),
      titleLarge: TextStyle(color: _lightText),
      titleMedium: TextStyle(color: _lightText),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _lightDialog,
      modalBackgroundColor: _lightDialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}