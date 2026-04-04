// lib/features/bookmarks/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/bookmark_model.dart';
import '../providers/bookmark_providers.dart';
import '../widgets/add_bookmark_dialog.dart';
import '../widgets/bookmark_card.dart';
import '../widgets/bookmark_filter_sheet.dart';
import '../widgets/bookmark_selection_app_bar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(filteredBookmarksProvider);
    final selectedIds = ref.watch(bookmarkSelectionProvider);
    final selectionNotifier = ref.read(bookmarkSelectionProvider.notifier);

    final selectionCount = selectedIds.length;
    final isSelectionMode = selectionCount > 0;

    // Resolve the single selected bookmark (for edit / copy)
    final singleSelected = selectionCount == 1
        ? bookmarksAsync.whenOrNull(
            data: (list) => list.firstWhere((b) => b.id == selectedIds.first),
          )
        : null;

    return Scaffold(
      appBar: isSelectionMode
          ? BookmarkSelectionAppBar(
              count: selectionCount,
              onClear: selectionNotifier.clear,
              urlToCopy: singleSelected?.url,
              onEdit: singleSelected != null
                  ? () {
                      selectionNotifier.clear();
                      showDialog(
                        context: context,
                        builder: (_) =>
                            AddBookmarkDialog(existingBookmark: singleSelected),
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
                  selectionNotifier.clear();
                });
              },
              isFavorite: bookmarksAsync.whenOrNull(
                data: (list) {
                  final sel = list
                      .where((b) => selectedIds.contains(b.id))
                      .toList();
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
                selectionNotifier.clear();
              },
            )
          : AppBar(
              title: const Text('L-Vault'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune, size: 32),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const BookmarkFilterSheet(),
                  ),
                ),
              ],
            ),

      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddBookmarkDialog(),
              ),
              child: const Icon(Icons.add),
            ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) => ref
                  .read(bookmarkFilterProvider.notifier)
                  .update((s) => s.copyWith(query: value)),
              decoration: InputDecoration(
                hintText: 'Search bookmarks...',
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
                  return const Center(child: Text('No bookmarks found'));
                }

                final grouped = _groupByDate(bookmarks);
                final sections = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: sections.fold<int>(
                    0,
                    (sum, date) => sum + 1 + grouped[date]!.length,
                  ),
                  itemBuilder: (context, index) {
                    int cursor = 0;
                    for (final date in sections) {
                      if (index == cursor) return _DateHeader(date: date);
                      cursor++;
                      final items = grouped[date]!;
                      if (index < cursor + items.length) {
                        final bookmark = items[index - cursor];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BookmarkCard(
                            bookmark: bookmark,
                            isSelected: selectedIds.contains(bookmark.id),
                            onLongPress: () =>
                                selectionNotifier.toggle(bookmark.id!),
                            onTap: () {
                              if (isSelectionMode) {
                                selectionNotifier.toggle(bookmark.id!);
                              } else {
                                /* Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WebViewPage(
                                      url: bookmark.url,
                                      title: bookmark.title,
                                    ),
                                  ),
                                ); */
                                launchUrl(
                                  Uri.parse(bookmark.url),
                                  mode: LaunchMode.externalApplication, // abre el navegador del sistema
                                );
                              }
                            },
                          ),
                        );
                      }
                      cursor += items.length;
                    }
                    return const SizedBox.shrink();
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

  Map<String, List<BookmarkModel>> _groupByDate(List<BookmarkModel> bookmarks) {
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
