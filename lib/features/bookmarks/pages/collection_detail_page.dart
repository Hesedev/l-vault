// lib/features/bookmarks/pages/collection_detail_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/bookmark_model.dart';
import '../../../data/models/collection_model.dart';
import '../../collections/providers/collection_providers.dart';
import '../../collections/widgets/add_collection_sheet.dart';
import '../providers/bookmark_providers.dart';
import '../widgets/add_bookmark_dialog.dart';
import '../widgets/bookmark_card.dart';
import '../widgets/bookmark_filter_sheet.dart';
import '../widgets/bookmark_selection_app_bar.dart';
import 'webview_page.dart';

class CollectionDetailPage extends ConsumerWidget {
  final CollectionWithCount collection;

  const CollectionDetailPage({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionId = collection.id!;
    final bookmarksAsync = ref.watch(
      filteredCollectionBookmarksProvider(collectionId),
    );
    final selectedIds = ref.watch(bookmarkSelectionProvider);
    final selectionNotifier = ref.read(bookmarkSelectionProvider.notifier);

    final selectionCount = selectedIds.length;
    final isSelectionMode = selectionCount > 0;

    final hasImage =
        collection.coverImage != null && collection.coverImage!.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: hasImage ? 200 : 120,
            pinned: true,
            flexibleSpace: isSelectionMode
                ? null
                : FlexibleSpaceBar(
                    title: Text(
                      collection.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                      ),
                    ),
                    background: hasImage
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(collection.coverImage!),
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _coloredBackground(context, collection.color),
                  ),
            actions: isSelectionMode
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.tune, size: 28),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            BookmarkFilterSheet(collectionId: collectionId),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 26),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            AddCollectionSheet(existingCollection: collection),
                      ),
                    ),
                  ],
            bottom: isSelectionMode
                ? _SelectionBarBottom(
                    count: selectionCount,
                    onClear: selectionNotifier.clear,
                    onEdit: selectionCount == 1
                        ? () {
                            bookmarksAsync.whenData((bookmarks) {
                              final id = selectedIds.first;
                              final bookmark = bookmarks.firstWhere(
                                (b) => b.id == id,
                              );
                              selectionNotifier.clear();
                              showDialog(
                                context: context,
                                builder: (_) => AddBookmarkDialog(
                                  existingBookmark: bookmark,
                                  collectionId: collectionId,
                                ),
                              );
                            });
                          }
                        : null,
                    onToggleFavorite: () async {
                      bookmarksAsync.whenData((bookmarks) async {
                        final repo = ref.read(bookmarkRepositoryProvider);
                        for (final id in selectedIds) {
                          final bookmark = bookmarks.firstWhere(
                            (b) => b.id == id,
                          );
                          await repo.toggleFavorite(bookmark);
                        }
                        ref.invalidate(
                          bookmarksByCollectionProvider(collectionId),
                        );
                        selectionNotifier.clear();
                      });
                    },
                    isFavorite: bookmarksAsync.whenOrNull(
                      data: (bookmarks) {
                        final selected = bookmarks
                            .where((b) => selectedIds.contains(b.id))
                            .toList();
                        if (selected.isEmpty) return null;
                        return selected.every((b) => b.isFavorite == 1);
                      },
                    ),
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete bookmarks?'),
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
                      final repo = ref.read(bookmarkRepositoryProvider);
                      for (final id in selectedIds) {
                        await repo.delete(id);
                      }
                      ref.invalidate(
                        bookmarksByCollectionProvider(collectionId),
                      );
                      ref.invalidate(collectionsProvider);
                      selectionNotifier.clear();
                    },
                  )
                : null,
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (value) {
                  ref
                      .read(
                        collectionBookmarkFilterProvider(collectionId).notifier,
                      )
                      .update((s) => s.copyWith(query: value));
                },
                decoration: InputDecoration(
                  hintText: 'Search in ${collection.name}...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Bookmarks list
          bookmarksAsync.when(
            data: (bookmarks) {
              if (bookmarks.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No bookmarks in this collection')),
                );
              }

              final grouped = _groupByDate(bookmarks);
              final sections = grouped.keys.toList();

              final items = <dynamic>[];
              for (final date in sections) {
                items.add(date);
                items.addAll(grouped[date]!);
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];

                    if (item is String) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 12),
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final bookmark = item as BookmarkModel;
                    final isSelected = selectedIds.contains(bookmark.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Consumer(
                        builder: (context, ref, _) {
                          return BookmarkCard(
                            bookmark: bookmark,
                            isSelected: isSelected,
                            onLongPress: () =>
                                selectionNotifier.toggle(bookmark.id!),
                            onTap: () {
                              if (isSelectionMode) {
                                selectionNotifier.toggle(bookmark.id!);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WebViewPage(
                                      url: bookmark.url,
                                      title: bookmark.title,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  }, childCount: items.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AddBookmarkDialog(collectionId: collectionId),
              ),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _coloredBackground(BuildContext context, String? colorHex) {
    Color color;
    if (colorHex != null) {
      try {
        final buffer = StringBuffer();
        if (colorHex.length == 7) buffer.write('ff');
        buffer.write(colorHex.replaceFirst('#', ''));
        color = Color(int.parse(buffer.toString(), radix: 16));
      } catch (_) {
        color = Theme.of(context).colorScheme.surface;
      }
    } else {
      color = Theme.of(context).colorScheme.surface;
    }
    return Container(
      color: color,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black38],
          ),
        ),
      ),
    );
  }

  Map<String, List<BookmarkModel>> _groupByDate(List<BookmarkModel> bookmarks) {
    final Map<String, List<BookmarkModel>> grouped = {};
    for (final b in bookmarks) {
      grouped.putIfAbsent(_formatDate(b.createdAt), () => []).add(b);
    }
    return grouped;
  }

  String _formatDate(String isoDate) {
    try {
      return DateFormat('MMMM d, yyyy').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }
}

/// Thin [PreferredSizeWidget] wrapper so [BookmarkSelectionAppBar] can be
/// mounted in [SliverAppBar.bottom] without duplicating any logic.
class _SelectionBarBottom extends StatelessWidget
    implements PreferredSizeWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleFavorite;
  final bool? isFavorite;

  const _SelectionBarBottom({
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
    return BookmarkSelectionAppBar(
      count: count,
      onClear: onClear,
      onDelete: onDelete,
      onEdit: onEdit,
      onToggleFavorite: onToggleFavorite,
      isFavorite: isFavorite,
    );
  }
}
