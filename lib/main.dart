// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_handler/share_handler.dart';

import 'core/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/bookmarks/pages/save_shared_link_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

// Cambio de StatefulWidget a ConsumerStatefulWidget porque ahora
// necesitamos ref para observar el themeProvider en build()
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    final handler = ShareHandler.instance;

    handler.getInitialSharedMedia().then((media) {
      final url = _extractUrl(media);
      if (url != null) _openSavePage(url);
    });

    handler.sharedMediaStream.listen((media) {
      final url = _extractUrl(media);
      if (url != null) _openSavePage(url);
    });
  }

  String? _extractUrl(SharedMedia? media) {
    if (media == null) return null;
    final text = media.content;
    if (text != null && text.isNotEmpty) {
      if (text.startsWith('http://') || text.startsWith('https://')) {
        return text;
      }
      final urlRegex = RegExp(r'https?://\S+');
      final match = urlRegex.firstMatch(text);
      if (match != null) return match.group(0);
    }
    return null;
  }

  void _openSavePage(String url) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => SaveSharedLinkPage(url: url),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch aquí — cuando el usuario cambia el tema, build() se
    // vuelve a ejecutar con el nuevo ThemeMode y toda la app cambia
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,       // usado cuando themeMode = light
      darkTheme: AppTheme.darkTheme,    // usado cuando themeMode = dark
      themeMode: themeMode,             // Flutter elige automáticamente
      navigatorKey: _navigatorKey,
      home: const AppShell(),
    );
  }
}