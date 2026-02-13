import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../data/models/collection_model.dart';

/// Repository Provider
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository();
});

/// Obtener todas las colecciones
final collectionsProvider = FutureProvider<List<CollectionModel>>((ref) async {
  final repo = ref.watch(collectionRepositoryProvider);
  return repo.getAll();
});
