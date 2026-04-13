// lib/features/collections/widgets/collection_card.dart

import 'dart:io';
import 'package:flutter/material.dart';

class CollectionCard extends StatelessWidget {
  final int id;
  final String name;
  final String? colorHex;
  final String? imagePath;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final int bookmarkCount;

  const CollectionCard({
    super.key,
    required this.id,
    required this.name,
    required this.colorHex,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.bookmarkCount,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = colorHex != null
        ? _hexToColor(colorHex!)
        : Theme.of(context).colorScheme.surface;

    // Si el color es personalizado (no null), siempre texto blanco
    // porque todos los colores de la paleta son oscuros.
    // Si es null (predeterminado), el texto sigue el color del tema:
    // blanco en oscuro, negro en claro.
    final Color textColor = colorHex != null
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    final Color subtitleColor = colorHex != null
        ? Colors.white70
        : Theme.of(context).hintColor;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// IMAGE SECTION
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: imagePath != null
                        ? Image.file(
                            File(imagePath!),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.black.withValues(alpha: 0.2),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                  ),
                ),

                /// NAME SECTION
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$bookmarkCount bookmarks',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: subtitleColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// SELECTION OVERLAY
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}