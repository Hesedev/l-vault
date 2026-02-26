// lib/data/models/bookmark_filter_model.dart

enum BookmarkOrderBy { creationDate, title, favorite }

class BookmarkFilter {
  final String query;
  final BookmarkOrderBy orderBy;
  final bool ascending;
  final bool favoritesOnly;

  const BookmarkFilter({
    this.query = '',
    this.orderBy = BookmarkOrderBy.creationDate,
    this.ascending = false,
    this.favoritesOnly = false,
  });

  BookmarkFilter copyWith({
    String? query,
    BookmarkOrderBy? orderBy,
    bool? ascending,
    bool? favoritesOnly,
  }) {
    return BookmarkFilter(
      query: query ?? this.query,
      orderBy: orderBy ?? this.orderBy,
      ascending: ascending ?? this.ascending,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }
}
