// lib/features/bookmarks/pages/collection_detail_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/bookmark_model.dart';
import '../../../data/models/collection_model.dart';
import '../../collections/providers/collection_providers.dart';
import '../../collections/widgets/add_collection_sheet.dart';
import '../providers/bookmark_providers.dart';
import '../widgets/add_bookmark_dialog.dart';
import '../widgets/bookmark_card.dart';
import '../widgets/bookmark_filter_sheet.dart';
import '../widgets/bookmark_selection_app_bar.dart';

class CollectionDetailPage extends ConsumerWidget {
  final CollectionModel collection;

  const CollectionDetailPage({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionId = collection.id!;

    // Leer la colección en vivo desde el provider para reflejar ediciones
    // en tiempo real (imagen, color, nombre) sin necesidad de volver a navegar.
    final liveCollection = ref.watch(collectionsProvider).whenOrNull(
          data: (list) {
            try {
              return list.firstWhere((c) => c.id == collectionId);
            } catch (_) {
              return null;
            }
          },
        );
    // Fallback al parámetro original mientras el provider carga
    final col = liveCollection ?? collection;

    final bookmarksAsync = ref.watch(
      filteredCollectionBookmarksProvider(collectionId),
    );
    final selectedIds = ref.watch(bookmarkSelectionProvider);
    final selectionNotifier = ref.read(bookmarkSelectionProvider.notifier);

    final selectionCount = selectedIds.length;
    final isSelectionMode = selectionCount > 0;

    final hasImage = col.coverImage != null && col.coverImage!.isNotEmpty;

    final singleSelected = selectionCount == 1
        ? bookmarksAsync.whenOrNull(
            data: (list) {
              try {
                return list.firstWhere((b) => b.id == selectedIds.first);
              } catch (_) {
                return null;
              }
            },
          )
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientEnd = isDark ? Colors.black54 : Colors.white60;

    // ── Selection mode ────────────────────────────────────────────────────────
    if (isSelectionMode) {
      return Scaffold(
        appBar: BookmarkSelectionAppBar(
          count: selectionCount,
          onClear: selectionNotifier.clear,
          urlToCopy: singleSelected?.url,
          onEdit: singleSelected != null
              ? () {
                  selectionNotifier.clear();
                  showDialog(
                    context: context,
                    builder: (_) => AddBookmarkDialog(
                      existingBookmark: singleSelected,
                      collectionId: collectionId,
                    ),
                  );
                }
              : null,
          onToggleFavorite: () async {
            bookmarksAsync.whenData((bookmarks) async {
              final repo = ref.read(bookmarkRepositoryProvider);
              for (final id in selectedIds) {
                final b = bookmarks.firstWhere((b) => b.id == id);
                await repo.toggleFavorite(b);
              }
              ref.invalidate(allBookmarksProvider);
              ref.invalidate(bookmarksByCollectionProvider(collectionId));
              selectionNotifier.clear();
            });
          },
          isFavorite: bookmarksAsync.whenOrNull(
            data: (list) {
              final sel =
                  list.where((b) => selectedIds.contains(b.id)).toList();
              if (sel.isEmpty) return null;
              return sel.every((b) => b.isFavorite == 1);
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
            ref.invalidate(allBookmarksProvider);
            ref.invalidate(bookmarksByCollectionProvider(collectionId));
            ref.invalidate(collectionsProvider);
            selectionNotifier.clear();
          },
        ),
        body: _BookmarkList(
          bookmarksAsync: bookmarksAsync,
          selectedIds: selectedIds,
          selectionNotifier: selectionNotifier,
          isSelectionMode: true,
          collectionId: collectionId,
          collectionName: col.name,
          searchQuery: (value) => ref
              .read(collectionBookmarkFilterProvider(collectionId).notifier)
              .update((s) => s.copyWith(query: value)),
        ),
      );
    }

    // ── Normal mode ───────────────────────────────────────────────────────────
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: hasImage ? 200 : 120,
            pinned: true,
            iconTheme: hasImage
                ? const IconThemeData(color: Colors.white)
                : IconThemeData(
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
            foregroundColor: hasImage
                ? Colors.white
                : Theme.of(context).appBarTheme.foregroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                col.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasImage ? Colors.white : null,
                  shadows: hasImage
                      ? const [Shadow(color: Colors.black45, blurRadius: 8)]
                      : null,
                ),
              ),
              background: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(col.coverImage!),
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [gradientEnd, Colors.transparent],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _coloredBackground(context, col.color),
            ),
            actions: [
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
                // Se pasa col (la versión viva) para que el sheet
                // abra con los datos actuales, no los del parámetro original
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddCollectionSheet(existingCollection: col),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (value) => ref
                    .read(
                      collectionBookmarkFilterProvider(collectionId).notifier,
                    )
                    .update((s) => s.copyWith(query: value)),
                decoration: InputDecoration(
                  hintText: 'Search in ${col.name}...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

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
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      if (item is String) return _DateHeader(date: item);
                      final bookmark = item as BookmarkModel;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookmarkCard(
                          bookmark: bookmark,
                          isSelected: selectedIds.contains(bookmark.id),
                          onLongPress: () =>
                              selectionNotifier.toggle(bookmark.id!),
                          onTap: () => launchUrl(
                            Uri.parse(bookmark.url),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddBookmarkDialog(collectionId: collectionId),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _coloredBackground(BuildContext context, String? colorHex) {
    final Color color;
    if (colorHex != null) {
      try {
        final buffer = StringBuffer();
        if (colorHex.length == 7) buffer.write('ff');
        buffer.write(colorHex.replaceFirst('#', ''));
        color = Color(int.parse(buffer.toString(), radix: 16));
      } catch (_) {
        return Container(color: Theme.of(context).colorScheme.surface);
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

  Map<String, List<BookmarkModel>> _groupByDate(
      List<BookmarkModel> bookmarks) {
    final grouped = <String, List<BookmarkModel>>{};
    for (final b in bookmarks) {
      grouped.putIfAbsent(_formatDate(b.createdAt), () => []).add(b);
    }
    return grouped;
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('MMMM d, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Bookmark list body (selection mode) ──────────────────────────────────────

class _BookmarkList extends StatelessWidget {
  final AsyncValue<List<BookmarkModel>> bookmarksAsync;
  final Set<int> selectedIds;
  final BookmarkSelectionNotifier selectionNotifier;
  final bool isSelectionMode;
  final int collectionId;
  final String collectionName;
  final void Function(String) searchQuery;

  const _BookmarkList({
    required this.bookmarksAsync,
    required this.selectedIds,
    required this.selectionNotifier,
    required this.isSelectionMode,
    required this.collectionId,
    required this.collectionName,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: searchQuery,
            decoration: InputDecoration(
              hintText: 'Search in $collectionName...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: bookmarksAsync.when(
            data: (bookmarks) {
              if (bookmarks.isEmpty) {
                return const Center(
                    child: Text('No bookmarks in this collection'));
              }
              final grouped = _groupByDate(bookmarks);
              final sections = grouped.keys.toList();
              final items = <dynamic>[];
              for (final date in sections) {
                items.add(date);
                items.addAll(grouped[date]!);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is String) return _DateHeader(date: item);
                  final bookmark = item as BookmarkModel;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BookmarkCard(
                      bookmark: bookmark,
                      isSelected: selectedIds.contains(bookmark.id),
                      onLongPress: () =>
                          selectionNotifier.toggle(bookmark.id!),
                      onTap: () => selectionNotifier.toggle(bookmark.id!),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Map<String, List<BookmarkModel>> _groupByDate(
      List<BookmarkModel> bookmarks) {
    final grouped = <String, List<BookmarkModel>>{};
    for (final b in bookmarks) {
      grouped.putIfAbsent(_formatDate(b.createdAt), () => []).add(b);
    }
    return grouped;
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('MMMM d, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _DateHeader extends StatelessWidget {
  final String date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        date,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w500,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}