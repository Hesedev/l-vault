// lib/features/bookmarks/widgets/bookmark_filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkvault/data/models/bookmark_filter_model.dart';
import 'package:linkvault/features/bookmarks/providers/bookmark_providers.dart';

class BookmarkFilterSheet extends ConsumerWidget {
  /// If null → home filter. If provided → collection-specific filter.
  final int? collectionId;

  const BookmarkFilterSheet({super.key, this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = collectionId == null
        ? ref.watch(bookmarkFilterProvider)
        : ref.watch(collectionBookmarkFilterProvider(collectionId));

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Filter options',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Order by',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _pill(
                    context,
                    selected: filter.orderBy == BookmarkOrderBy.creationDate,
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    onTap: () => _setOrder(ref, BookmarkOrderBy.creationDate),
                  ),
                  _pill(
                    context,
                    selected: filter.orderBy == BookmarkOrderBy.title,
                    icon: Icons.sort_by_alpha_rounded,
                    label: 'Title',
                    onTap: () => _setOrder(ref, BookmarkOrderBy.title),
                  ),
                  _pill(
                    context,
                    selected: filter.orderBy == BookmarkOrderBy.favorite,
                    icon: Icons.star_rounded,
                    label: 'Favorites',
                    onTap: () => _setOrder(ref, BookmarkOrderBy.favorite),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Direction',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _pill(
                      context,
                      selected: filter.ascending,
                      icon: Icons.arrow_upward_rounded,
                      label: 'Ascending',
                      onTap: () => _setDirection(ref, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _pill(
                      context,
                      selected: !filter.ascending,
                      icon: Icons.arrow_downward_rounded,
                      label: 'Descending',
                      onTap: () => _setDirection(ref, false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Favorites only toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text('Favorites only', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  Switch(
                    value: filter.favoritesOnly,
                    onChanged: (val) => _setFavoritesOnly(ref, val),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setOrder(WidgetRef ref, BookmarkOrderBy order) {
    if (collectionId == null) {
      ref
          .read(bookmarkFilterProvider.notifier)
          .update((s) => s.copyWith(orderBy: order));
    } else {
      ref
          .read(collectionBookmarkFilterProvider(collectionId).notifier)
          .update((s) => s.copyWith(orderBy: order));
    }
  }

  void _setDirection(WidgetRef ref, bool ascending) {
    if (collectionId == null) {
      ref
          .read(bookmarkFilterProvider.notifier)
          .update((s) => s.copyWith(ascending: ascending));
    } else {
      ref
          .read(collectionBookmarkFilterProvider(collectionId).notifier)
          .update((s) => s.copyWith(ascending: ascending));
    }
  }

  void _setFavoritesOnly(WidgetRef ref, bool val) {
    if (collectionId == null) {
      ref
          .read(bookmarkFilterProvider.notifier)
          .update((s) => s.copyWith(favoritesOnly: val));
    } else {
      ref
          .read(collectionBookmarkFilterProvider(collectionId).notifier)
          .update((s) => s.copyWith(favoritesOnly: val));
    }
  }

  Widget _pill(
    BuildContext context, {
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: selected
              ? colors.primary
              : colors.surface.withValues(alpha: 0.6),
          border: Border.all(
            color: selected
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? Colors.white
                  : colors.onSurface.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : colors.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
