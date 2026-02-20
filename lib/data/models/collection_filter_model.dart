// lib/data/models/collection_filter_model.dart

enum CollectionOrderBy { content, creationDate, name }

class CollectionFilter {
  final String query;
  final CollectionOrderBy orderBy;
  final bool ascending;

  const CollectionFilter({
    this.query = '',
    this.orderBy = CollectionOrderBy.creationDate,
    this.ascending = false,
  });

  CollectionFilter copyWith({
    String? query,
    CollectionOrderBy? orderBy,
    bool? ascending,
  }) {
    return CollectionFilter(
      query: query ?? this.query,
      orderBy: orderBy ?? this.orderBy,
      ascending: ascending ?? this.ascending,
    );
  }
}
