// lib/services/metadata_service.dart
//
// Requiere en pubspec.yaml:
//   any_link_preview: ^3.0.3
//   http: ^1.2.2

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:any_link_preview/any_link_preview.dart';
import 'package:http/http.dart' as http;

class LinkMetadata {
  final String? title;
  final String? imageUrl;
  final String? description;

  const LinkMetadata({this.title, this.imageUrl, this.description});
}

class MetadataService {
  static const _timeout = Duration(seconds: 12);

  // Proveedores oEmbed: host (sin www) → base del endpoint
  static const _oembedProviders = {
    'youtube.com':      'https://www.youtube.com/oembed',
    'youtu.be':         'https://www.youtube.com/oembed',
    'vimeo.com':        'https://vimeo.com/api/oembed.json',
  };

  Future<LinkMetadata> fetch(String rawUrl) async {
    final url = _ensureScheme(rawUrl.trim());
    dev.log('[MetadataService] Fetching: $url');

    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase().replaceFirst('www.', '');

      // 1. Proveedores oEmbed conocidos
      final oembedBase = _oembedProviders[host];
      if (oembedBase != null) {
        dev.log('[MetadataService] → oEmbed path ($host)');
        return await _fetchOEmbed(url, oembedBase);
      }

      // 2. Wikipedia (cualquier idioma)
      if (host.contains('wikipedia.org')) {
        dev.log('[MetadataService] → Wikipedia path');
        return await _fetchWikipedia(uri);
      }

      // 3. Genérico via any_link_preview
      dev.log('[MetadataService] → Generic path');
      return await _fetchGeneric(url);
    } catch (e, stack) {
      dev.log('[MetadataService] Top-level error: $e', stackTrace: stack);
      return const LinkMetadata();
    }
  }

  // ─── oEmbed genérico (YouTube, Vimeo, TikTok, Spotify, Twitter…) ─────────
  Future<LinkMetadata> _fetchOEmbed(String url, String providerBase) async {
    try {
      final oembedUri = Uri.parse(
        '$providerBase?url=${Uri.encodeComponent(url)}&format=json',
      );
      final response = await http.get(oembedUri).timeout(_timeout);
      dev.log('[MetadataService] oEmbed status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LinkMetadata(
          title: json['title'] as String?,
          imageUrl: json['thumbnail_url'] as String?,
        );
      }
    } catch (e) {
      dev.log('[MetadataService] oEmbed error: $e');
    }
    return const LinkMetadata();
  }

  // ─── Wikipedia REST API ───────────────────────────────────────────────────
  Future<LinkMetadata> _fetchWikipedia(Uri uri) async {
    try {
      final pathParts = uri.pathSegments;
      if (pathParts.length < 2 || pathParts[0] != 'wiki') {
        return const LinkMetadata();
      }
      final article = pathParts[1];
      final lang = uri.host.split('.').first;

      final apiUri = Uri(
        scheme: 'https',
        host: '$lang.wikipedia.org',
        pathSegments: ['api', 'rest_v1', 'page', 'summary', article],
      );

      final response = await http
          .get(apiUri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);
      dev.log('[MetadataService] Wikipedia status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LinkMetadata(
          title: json['title'] as String?,
          imageUrl:
              (json['thumbnail'] as Map<String, dynamic>?)?['source']
                  as String?,
          description: json['description'] as String?,
        );
      }
    } catch (e) {
      dev.log('[MetadataService] Wikipedia error: $e');
    }
    return const LinkMetadata();
  }

  // ─── Generic via any_link_preview ────────────────────────────────────────
  Future<LinkMetadata> _fetchGeneric(String url) async {
    const agents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      'WhatsApp/2.21.12.21 A',
    ];

    for (final agent in agents) {
      try {
        dev.log('[MetadataService] Trying agent: $agent');
        final meta = await AnyLinkPreview.getMetadata(
          link: url,
          cache: null,
          userAgent: agent,
        ).timeout(_timeout);

        dev.log(
          '[MetadataService] Result → title: ${meta?.title}, '
          'image: ${meta?.image}',
        );

        if (meta != null && (meta.title != null || meta.image != null)) {
          return LinkMetadata(
            title: _clean(meta.title),
            imageUrl: _cleanImage(meta.image),
            description: meta.desc,
          );
        }
      } catch (e) {
        dev.log('[MetadataService] Agent error: $e');
      }
    }

    return const LinkMetadata();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _ensureScheme(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }

  String? _clean(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim();
    if (t.startsWith('http') || t.length < 2) return null;
    return t;
  }

  String? _cleanImage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final img = raw.trim();
    if (!img.startsWith('http')) return null;
    return img;
  }

  static String fallbackTitle(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}