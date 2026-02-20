// lib/features/collections/widgets/collections_filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkvault/data/models/collection_filter_model.dart';
import 'package:linkvault/features/collections/providers/collection_providers.dart';

class CollectionsFilterSheet extends ConsumerWidget {
  const CollectionsFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(collectionFilterProvider);
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
              /// Handle
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

              /// Title
              Text(
                "Filter options",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 28),

              /// ORDER BY
              Text(
                "Order by",
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
                    ref,
                    filter.orderBy == CollectionOrderBy.content,
                    icon: Icons.layers_rounded,
                    label: "Content",
                    onTap: () => _updateOrder(ref, CollectionOrderBy.content),
                  ),
                  _pill(
                    context,
                    ref,
                    filter.orderBy == CollectionOrderBy.creationDate,
                    icon: Icons.calendar_today_rounded,
                    label: "Creation Date",
                    onTap: () =>
                        _updateOrder(ref, CollectionOrderBy.creationDate),
                  ),
                  _pill(
                    context,
                    ref,
                    filter.orderBy == CollectionOrderBy.name,
                    icon: Icons.sort_by_alpha_rounded,
                    label: "Name",
                    onTap: () => _updateOrder(ref, CollectionOrderBy.name),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              /// DIRECTION
              Text(
                "Direction",
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
                      ref,
                      filter.ascending,
                      icon: Icons.arrow_upward_rounded,
                      label: "Ascending",
                      onTap: () => _updateDirection(ref, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _pill(
                      context,
                      ref,
                      !filter.ascending,
                      icon: Icons.arrow_downward_rounded,
                      label: "Descending",
                      onTap: () => _updateDirection(ref, false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateOrder(WidgetRef ref, CollectionOrderBy value) {
    ref
        .read(collectionFilterProvider.notifier)
        .update((state) => state.copyWith(orderBy: value));
  }

  void _updateDirection(WidgetRef ref, bool ascending) {
    ref
        .read(collectionFilterProvider.notifier)
        .update((state) => state.copyWith(ascending: ascending));
  }

  Widget _pill(
    BuildContext context,
    WidgetRef ref,
    bool selected, {
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
