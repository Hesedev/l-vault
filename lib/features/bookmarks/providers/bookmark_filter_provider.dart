import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookmarkFilterState {
  final bool favoritesOnly;
  final int? collectionId;
  final List<int> tagIds;

  const BookmarkFilterState({
    this.favoritesOnly = false,
    this.collectionId,
    this.tagIds = const [],
  });

  BookmarkFilterState copyWith({
    bool? favoritesOnly,
    int? collectionId,
    List<int>? tagIds,
  }) {
    return BookmarkFilterState(
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      collectionId: collectionId ?? this.collectionId,
      tagIds: tagIds ?? this.tagIds,
    );
  }
}

final bookmarkFilterProvider =
    StateNotifierProvider<BookmarkFilterNotifier, BookmarkFilterState>(
      (ref) => BookmarkFilterNotifier(),
    );

class BookmarkFilterNotifier extends StateNotifier<BookmarkFilterState> {
  BookmarkFilterNotifier() : super(const BookmarkFilterState());

  void toggleFavorites() {
    state = state.copyWith(favoritesOnly: !state.favoritesOnly);
  }

  void setCollection(int? id) {
    state = state.copyWith(collectionId: id);
  }

  void setTags(List<int> tags) {
    state = state.copyWith(tagIds: tags);
  }

  void clear() {
    state = const BookmarkFilterState();
  }
}
