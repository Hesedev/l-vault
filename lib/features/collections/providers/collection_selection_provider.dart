// lib/features/collections/providers/collection_selection_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

final collectionSelectionProvider =
    StateNotifierProvider<CollectionSelectionNotifier, Set<int>>(
      (ref) => CollectionSelectionNotifier(),
    );

class CollectionSelectionNotifier extends StateNotifier<Set<int>> {
  CollectionSelectionNotifier() : super({});

  void toggle(int id) {
    final newSet = {...state};
    if (newSet.contains(id)) {
      newSet.remove(id);
    } else {
      newSet.add(id);
    }
    state = newSet;
  }

  void clear() {
    state = {};
  }

  bool isSelected(int id) {
    return state.contains(id);
  }
}
