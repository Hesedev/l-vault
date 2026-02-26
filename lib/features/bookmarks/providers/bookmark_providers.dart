// lib/features/bookmarks/providers/bookmark_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkvault/data/models/bookmark_filter_model.dart';

import '../../../data/repositories/bookmark_repository.dart';
import '../../../data/models/bookmark_model.dart';

/// Repository
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository();
});

/// All bookmarks (Home)
final allBookmarksProvider = FutureProvider<List<BookmarkModel>>((ref) async {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return repo.getAll();
});

/// Bookmarks by collection
final bookmarksByCollectionProvider =
    FutureProvider.family<List<BookmarkModel>, int?>((ref, collectionId) async {
      final repo = ref.watch(bookmarkRepositoryProvider);
      return repo.getByCollection(collectionId);
    });

/// Filter for home page
final bookmarkFilterProvider = StateProvider<BookmarkFilter>((ref) {
  return const BookmarkFilter();
});

/// Filtered bookmarks for home
final filteredBookmarksProvider = Provider<AsyncValue<List<BookmarkModel>>>((
  ref,
) {
  final bookmarksAsync = ref.watch(allBookmarksProvider);
  final filter = ref.watch(bookmarkFilterProvider);

  return bookmarksAsync.whenData((bookmarks) {
    List<BookmarkModel> list = [...bookmarks];

    if (filter.favoritesOnly) {
      list = list.where((b) => b.isFavorite == 1).toList();
    }

    if (filter.query.isNotEmpty) {
      final q = filter.query.toLowerCase();
      list = list
          .where(
            (b) =>
                (b.title?.toLowerCase().contains(q) ?? false) ||
                b.url.toLowerCase().contains(q) ||
                (b.notes?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    list.sort((a, b) {
      int result;
      switch (filter.orderBy) {
        case BookmarkOrderBy.title:
          result = (a.title ?? a.url).compareTo(b.title ?? b.url);
          break;
        case BookmarkOrderBy.favorite:
          result = a.isFavorite.compareTo(b.isFavorite);
          break;
        case BookmarkOrderBy.creationDate:
          result = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return filter.ascending ? result : -result;
    });

    return list;
  });
});

/// Filter for collection page
final collectionBookmarkFilterProvider =
    StateProvider.family<BookmarkFilter, int?>((ref, collectionId) {
      return const BookmarkFilter();
    });

/// Filtered bookmarks for a specific collection
final filteredCollectionBookmarksProvider =
    Provider.family<AsyncValue<List<BookmarkModel>>, int?>((ref, collectionId) {
      final bookmarksAsync = ref.watch(
        bookmarksByCollectionProvider(collectionId),
      );
      final filter = ref.watch(collectionBookmarkFilterProvider(collectionId));

      return bookmarksAsync.whenData((bookmarks) {
        List<BookmarkModel> list = [...bookmarks];

        if (filter.favoritesOnly) {
          list = list.where((b) => b.isFavorite == 1).toList();
        }

        if (filter.query.isNotEmpty) {
          final q = filter.query.toLowerCase();
          list = list
              .where(
                (b) =>
                    (b.title?.toLowerCase().contains(q) ?? false) ||
                    b.url.toLowerCase().contains(q) ||
                    (b.notes?.toLowerCase().contains(q) ?? false),
              )
              .toList();
        }

        list.sort((a, b) {
          int result;
          switch (filter.orderBy) {
            case BookmarkOrderBy.title:
              result = (a.title ?? a.url).compareTo(b.title ?? b.url);
              break;
            case BookmarkOrderBy.favorite:
              result = a.isFavorite.compareTo(b.isFavorite);
              break;
            case BookmarkOrderBy.creationDate:
              result = a.createdAt.compareTo(b.createdAt);
              break;
          }
          return filter.ascending ? result : -result;
        });

        return list;
      });
    });

/// Selection provider for bookmarks
final bookmarkSelectionProvider =
    StateNotifierProvider<BookmarkSelectionNotifier, Set<int>>(
      (ref) => BookmarkSelectionNotifier(),
    );

class BookmarkSelectionNotifier extends StateNotifier<Set<int>> {
  BookmarkSelectionNotifier() : super({});

  void toggle(int id) {
    final newSet = {...state};
    if (newSet.contains(id)) {
      newSet.remove(id);
    } else {
      newSet.add(id);
    }
    state = newSet;
  }

  void clear() => state = {};
  bool isSelected(int id) => state.contains(id);
}
