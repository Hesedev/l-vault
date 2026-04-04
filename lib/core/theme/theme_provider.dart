// lib/core/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// La key con la que se guarda la preferencia en shared_preferences
const _kThemeKey = 'is_dark_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Valor inicial mientras carga la preferencia — se asume oscuro
    // porque es el tema original de la app
    _loadFromPrefs();
    return ThemeMode.dark;
  }

  // Lee la preferencia guardada y actualiza el estado
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kThemeKey) ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // Alterna entre oscuro y claro, y guarda la preferencia
  Future<void> toggle() async {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kThemeKey, !isDark);
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);