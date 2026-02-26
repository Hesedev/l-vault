// lib/features/bookmarks/widgets/bookmark_selection_app_bar.dart

import 'package:flutter/material.dart';

class BookmarkSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleFavorite;
  final bool? isFavorite; // null = mixed selection

  const BookmarkSelectionAppBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onDelete,
    this.onEdit,
    this.onToggleFavorite,
    this.isFavorite,
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
        if (onToggleFavorite != null)
          IconButton(
            icon: Icon(isFavorite == true ? Icons.star : Icons.star_border),
            onPressed: onToggleFavorite,
          ),
        if (onEdit != null)
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
        IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
      ],
    );
  }
}
