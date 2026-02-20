import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  void clear() {
    state = {};
  }

  bool isSelected(int id) {
    return state.contains(id);
  }
}
