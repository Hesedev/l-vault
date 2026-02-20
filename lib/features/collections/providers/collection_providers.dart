// lib/features/collections/providers/collection_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkvault/data/models/collection_filter_model.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../data/models/collection_model.dart';

/// Repository Provider
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository();
});

/// Obtener todas las colecciones
final collectionsProvider = FutureProvider<List<CollectionWithCount>>((
  ref,
) async {
  final repo = ref.watch(collectionRepositoryProvider);
  return repo.getAllWithCount();
});

// Filtro y ordenamiento de colecciones

final collectionFilterProvider = StateProvider<CollectionFilter>((ref) {
  return const CollectionFilter();
});

final filteredCollectionsProvider =
    Provider<AsyncValue<List<CollectionWithCount>>>((ref) {
      final collectionsAsync = ref.watch(collectionsProvider);
      final filter = ref.watch(collectionFilterProvider);

      return collectionsAsync.whenData((collections) {
        List<CollectionWithCount> list = [...collections];

        if (filter.query.isNotEmpty) {
          list = list
              .where(
                (c) =>
                    c.name.toLowerCase().contains(filter.query.toLowerCase()),
              )
              .toList();
        }

        list.sort((a, b) {
          int result;

          switch (filter.orderBy) {
            case CollectionOrderBy.name:
              result = a.name.compareTo(b.name);
              break;

            case CollectionOrderBy.creationDate:
              result = a.createdAt.compareTo(b.createdAt);
              break;

            case CollectionOrderBy.content:
              result = a.bookmarkCount.compareTo(b.bookmarkCount);
              break;
          }

          return filter.ascending ? result : -result;
        });

        return list;
      });
    });
