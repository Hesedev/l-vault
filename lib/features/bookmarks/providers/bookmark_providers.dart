import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bookmark_model.dart';
import '../../../data/repositories/bookmark_repository.dart';

/// Repository Provider
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository();
});

/// Provider para obtener bookmarks por colección
final bookmarksByCollectionProvider =
    FutureProvider.family<List<BookmarkModel>, int?>((ref, collectionId) async {
      final repo = ref.watch(bookmarkRepositoryProvider);
      return repo.getByCollection(collectionId);
    });

/// Controller simple para acciones CRUD
final bookmarkActionsProvider = Provider<BookmarkActions>((ref) {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return BookmarkActions(repo, ref);
});

class BookmarkActions {
  final BookmarkRepository repository;
  final Ref ref;

  BookmarkActions(this.repository, this.ref);

  Future<void> addBookmark(BookmarkModel bookmark) async {
    await repository.insert(bookmark);

    // refrescar listas
    ref.invalidate(bookmarksByCollectionProvider);
  }

  Future<void> deleteBookmark(int id) async {
    await repository.delete(id);

    ref.invalidate(bookmarksByCollectionProvider);
  }
}
