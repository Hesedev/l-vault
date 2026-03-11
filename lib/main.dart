// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_handler/share_handler.dart';

import 'core/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/bookmarks/pages/save_shared_link_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    final handler = ShareHandler.instance;

    // App lanzada desde "Compartir con L-Vault" estando cerrada
    handler.getInitialSharedMedia().then((media) {
      final url = _extractUrl(media);
      if (url != null) _openSavePage(url);
    });

    // App ya abierta y el usuario comparte un link
    handler.sharedMediaStream.listen((media) {
      final url = _extractUrl(media);
      if (url != null) _openSavePage(url);
    });
  }

  String? _extractUrl(SharedMedia? media) {
    if (media == null) return null;
    // Texto plano compartido (URLs vienen aquí)
    final text = media.content;
    if (text != null && text.isNotEmpty) {
      if (text.startsWith('http://') || text.startsWith('https://')) {
        return text;
      }
      // Algunos apps comparten texto con la URL embebida — intentar extraerla
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: _navigatorKey,
      home: const AppShell(),
    );
  }
}
