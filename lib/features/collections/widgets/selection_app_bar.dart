// lib/features/collections/widgets/selection_app_bar.dart

import 'package:flutter/material.dart';

class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const SelectionAppBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close), onPressed: onClear),
      title: Text('$count selected'),
      actions: [
        if (onEdit != null)
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
        IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
      ],
    );
  }
}
