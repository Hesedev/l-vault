// lib/features/collections/pages/collections_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkvault/features/collections/widgets/collections_filter_sheet.dart';
import 'package:linkvault/features/collections/widgets/selection_app_bar.dart';

import '../providers/collection_selection_provider.dart';
import '../providers/collection_providers.dart';

import '../widgets/collection_card.dart';
import '../widgets/add_collection_sheet.dart';

class CollectionsPage extends ConsumerWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(filteredCollectionsProvider);
    final selectedIds = ref.watch(collectionSelectionProvider);
    final selectionNotifier = ref.read(collectionSelectionProvider.notifier);

    final selectionCount = selectedIds.length;
    final isSelectionMode = selectionCount > 0;

    return Scaffold(
      appBar: isSelectionMode
          ? SelectionAppBar(
              count: selectionCount,
              onClear: selectionNotifier.clear,
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete collections?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;
                final repo = ref.read(collectionRepositoryProvider);
                for (final id in selectedIds) {
                  await repo.delete(id);
                }
                selectionNotifier.clear();
                ref.invalidate(collectionsProvider);
              },
              onEdit: selectionCount == 1
                  ? () {
                      collectionsAsync.whenData((collections) {
                        final id = selectedIds.first;

                        final collection = collections.firstWhere(
                          (c) => c.id == id,
                        );

                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AddCollectionSheet(
                            existingCollection: collection,
                          ),
                        );
                      });

                      selectionNotifier.clear();
                    }
                  : null,
            )
          : AppBar(
              title: const Text('Collections'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune, size: 32),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CollectionsFilterSheet(),
                    );
                  },
                ),
              ],
            ),

      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddCollectionSheet(),
                );
              },
              child: const Icon(Icons.add),
            ),

      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                ref
                    .read(collectionFilterProvider.notifier)
                    .update((state) => state.copyWith(query: value));
              },
              decoration: InputDecoration(
                hintText: "Search collections...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// GRID
          Expanded(
            child: collectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) {
                  return const Center(child: Text('No collections found'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: collections.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final collection = collections[index];
                    final isSelected = selectedIds.contains(collection.id);

                    return Consumer(
                      builder: (context, ref, _) {
                        return CollectionCard(
                          id: collection.id!,
                          name: collection.name,
                          colorHex: collection.color,
                          imagePath: collection.coverImage,
                          bookmarkCount: collection.bookmarkCount,
                          isSelected: isSelected,
                          onLongPress: () {
                            selectionNotifier.toggle(collection.id!);
                          },
                          onTap: () {
                            if (isSelectionMode) {
                              selectionNotifier.toggle(collection.id!);
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
