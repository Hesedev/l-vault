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
  final VoidCallback? onLongPress; // ahora opcional
  final int bookmarkCount;

  const CollectionCard({
    super.key,
    required this.id,
    required this.name,
    required this.colorHex,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
    this.onLongPress, // opcional
    required this.bookmarkCount,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = colorHex != null
        ? _hexToColor(colorHex!)
        : Theme.of(context).colorScheme.surface;

    // Calcula si el color de fondo es claro u oscuro
    final bool isLightBackground = colorHex != null
        ? backgroundColor.computeLuminance() > 0.3
        : Theme.of(context).brightness == Brightness.light;

    final Color textColor = isLightBackground
        ? Colors.black87
        : Colors.white;

    final Color subtitleColor = isLightBackground
        ? Colors.black54
        : Colors.white70;

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
                        '$bookmarkCount ${bookmarkCount == 1 ? 'item' : 'items'}',
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
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
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