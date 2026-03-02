// lib/features/bookmarks/widgets/bookmark_selection_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookmarkSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleFavorite;
  final bool? isFavorite;

  /// The URL to copy — only shown when a single bookmark is selected.
  final String? urlToCopy;

  const BookmarkSelectionAppBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onDelete,
    this.onEdit,
    this.onToggleFavorite,
    this.isFavorite,
    this.urlToCopy,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onClear,
      ),
      title: Text('$count selected'),
      actions: [
        // Copy link — only when one bookmark selected
        if (urlToCopy != null)
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Copy link',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: urlToCopy!));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              onClear(); // deselect after copying
            },
          ),

        // Toggle favorite
        if (onToggleFavorite != null)
          IconButton(
            icon: Icon(
              isFavorite == true
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
            ),
            tooltip: isFavorite == true
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: onToggleFavorite,
          ),

        // Edit (single selection only)
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),

        // Delete
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      ],
    );
  }
}
