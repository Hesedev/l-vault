// lib/core/app_shell.dart

import 'package:flutter/material.dart';
import '../features/bookmarks/pages/home_page.dart';
import '../features/collections/pages/collections_page.dart';
import '../features/settings/pages/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    CollectionsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            backgroundColor:
                Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            elevation: 0,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled, size: 32),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.layers, size: 32),
                label: 'Collections',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings, size: 32),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}