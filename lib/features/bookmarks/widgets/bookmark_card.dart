// lib/features/bookmarks/widgets/bookmark_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../../../data/models/bookmark_model.dart';

class BookmarkCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = bookmark.image != null && bookmark.image!.isNotEmpty;
    final isRemoteImage = hasImage && bookmark.image!.startsWith('http');

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
            // URL bar
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

            // Content row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                                errorWidget: (_, __, ___) =>
                                    _placeholder(context),
                              )
                            : Image.file(
                                File(bookmark.image!),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),

                  if (hasImage) const SizedBox(width: 12),

                  // Text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (bookmark.title != null &&
                            bookmark.title!.isNotEmpty)
                          Text(
                            bookmark.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        if (bookmark.title != null &&
                            bookmark.title!.isNotEmpty)
                          const SizedBox(height: 4),
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

                  // Favorite icon
                  if (bookmark.isFavorite == 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.star, size: 16, color: Colors.amber),
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
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}
