// lib/services/metadata_service.dart

import 'package:http/http.dart' as http;

class LinkMetadata {
  final String? title;
  final String? imageUrl;
  final String? siteName;

  const LinkMetadata({this.title, this.imageUrl, this.siteName});
}

class MetadataService {
  /// Fetches Open Graph / basic metadata from a URL.
  /// Returns null fields if not found or on error.
  Future<LinkMetadata> fetch(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0 LinkVault/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return const LinkMetadata();

      final body = response.body;

      final title =
          _extractMeta(body, 'og:title') ??
          _extractMeta(body, 'twitter:title') ??
          _extractTitle(body);

      final imageUrl =
          _extractMeta(body, 'og:image') ?? _extractMeta(body, 'twitter:image');

      final siteName = _extractMeta(body, 'og:site_name') ?? uri.host;

      return LinkMetadata(
        title: title,
        imageUrl: imageUrl != null ? _resolveUrl(imageUrl, uri) : null,
        siteName: siteName,
      );
    } catch (_) {
      return const LinkMetadata();
    }
  }

  String? _extractMeta(String html, String property) {
    // og:image, og:title, etc.
    final patterns = [
      RegExp(
        'property=["\']$property["\'][^>]*content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        'content=["\']([^"\']+)["\'][^>]*property=["\']$property["\']',
        caseSensitive: false,
      ),
      RegExp(
        'name=["\']$property["\'][^>]*content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        'content=["\']([^"\']+)["\'][^>]*name=["\']$property["\']',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) return match.group(1);
    }
    return null;
  }

  String? _extractTitle(String html) {
    final match = RegExp(
      r'<title[^>]*>([^<]+)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    return match?.group(1)?.trim();
  }

  String _resolveUrl(String imageUrl, Uri base) {
    if (imageUrl.startsWith('http')) return imageUrl;
    if (imageUrl.startsWith('//')) return '${base.scheme}:$imageUrl';
    if (imageUrl.startsWith('/')) {
      return '${base.scheme}://${base.host}$imageUrl';
    }
    return imageUrl;
  }
}
