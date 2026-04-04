// lib/features/bookmarks/widgets/bookmark_card.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bookmark_model.dart';
import '../../collections/providers/collection_providers.dart';

class BookmarkCard extends ConsumerWidget {
  final BookmarkModel bookmark;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasImage = bookmark.image != null && bookmark.image!.isNotEmpty;
    final isRemoteImage = hasImage && bookmark.image!.startsWith('http');

    // Resolve collection only if this bookmark belongs to one
    final matchedCollection = bookmark.collectionId != null
        ? ref
              .watch(collectionsProvider)
              .whenOrNull(
                data: (list) {
                  try {
                    return list.firstWhere(
                      (c) => c.id == bookmark.collectionId,
                    );
                  } catch (_) {
                    return null;
                  }
                },
              )
        : null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Collection pill — bottom of card ─────────────────────────
            if (matchedCollection != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: _CollectionPill(
                  name: matchedCollection.name,
                  colorHex: matchedCollection.color,
                ),
              ),

            // ── URL bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Text(
                bookmark.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 11,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Content row ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                0,
                12,
                matchedCollection != null ? 8 : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: isRemoteImage
                            ? CachedNetworkImage(
                                imageUrl: bookmark.image!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) =>
                                    _placeholder(context),
                              )
                            : Image.file(
                                File(bookmark.image!),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),

                  if (hasImage) const SizedBox(width: 12),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (bookmark.title != null &&
                            bookmark.title!.isNotEmpty) ...[
                          Text(
                            bookmark.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          _siteName(bookmark.url),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        if (bookmark.notes != null &&
                            bookmark.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            bookmark.notes!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Favorite star
                  if (bookmark.isFavorite == 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(Icons.image, color: Colors.white54, size: 24),
      ),
    );
  }

  String _siteName(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}

class _CollectionPill extends StatelessWidget {
  final String name;
  final String? colorHex;

  const _CollectionPill({required this.name, this.colorHex});

  @override
  Widget build(BuildContext context) {
    final bg =
        _parseColor(colorHex) ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.25);
    final textColor = bg.computeLuminance() > 0.4
        ? Colors.black87
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      final buffer = StringBuffer();
      if (hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }
}
