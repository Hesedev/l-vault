import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/tag_model.dart';
import '../../../data/repositories/tag_repository.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository();
});

final tagsProvider = FutureProvider<List<TagModel>>((ref) async {
  final repo = ref.watch(tagRepositoryProvider);
  return repo.getAll();
});
