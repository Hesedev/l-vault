// lib/features/bookmarks/pages/save_shared_link_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bookmark_model.dart';
import '../../../data/models/collection_model.dart';
import '../../../services/metadata_service.dart';
import '../../collections/providers/collection_providers.dart';
import '../../collections/widgets/add_collection_sheet.dart';
import '../providers/bookmark_providers.dart';

class SaveSharedLinkPage extends ConsumerStatefulWidget {
  final String url;
  const SaveSharedLinkPage({super.key, required this.url});

  @override
  ConsumerState<SaveSharedLinkPage> createState() => _SaveSharedLinkPageState();
}

class _SaveSharedLinkPageState extends ConsumerState<SaveSharedLinkPage> {
  final _notesController = TextEditingController();

  int? _selectedCollectionId;
  bool _isSaving = false;
  bool _fetchingMeta = true;
  String? _resolvedTitle;
  String? _resolvedImage;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    final meta = await MetadataService().fetch(widget.url);
    if (!mounted) return;
    setState(() {
      _fetchingMeta = false;
      _resolvedTitle = (meta.title?.isNotEmpty == true)
          ? meta.title
          : MetadataService.fallbackTitle(widget.url);
      _resolvedImage = meta.imageUrl;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final repo = ref.read(bookmarkRepositoryProvider);

    await repo.insert(
      BookmarkModel(
        url: widget.url,
        title: _resolvedTitle ?? MetadataService.fallbackTitle(widget.url),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        image: _resolvedImage,
        collectionId: _selectedCollectionId,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    ref.invalidate(allBookmarksProvider);
    if (_selectedCollectionId != null) {
      ref.invalidate(bookmarksByCollectionProvider(_selectedCollectionId));
      ref.invalidate(collectionsProvider);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Save link')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddCollectionSheet(),
          );
          ref.invalidate(collectionsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── Collections picker ───────────────────────────────────────────
          Expanded(
            child: collectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) {
                  return Center(
                    child: Text(
                      'No collections yet.\nTap + to create one.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        onChanged: (value) => ref
                            .read(collectionFilterProvider.notifier)
                            .update((s) => s.copyWith(query: value)),
                        decoration: InputDecoration(
                          hintText: 'Search collections...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                        itemCount: collections.length,
                        itemBuilder: (context, index) {
                          final col = collections[index];
                          final isSelected = _selectedCollectionId == col.id;
                          return _CollectionTile(
                            collection: col,
                            isSelected: isSelected,
                            onTap: () => setState(() {
                              _selectedCollectionId = isSelected
                                  ? null
                                  : col.id;
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),

          // ── Bottom panel ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // URL row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    if (_fetchingMeta)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Notes
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving || _fetchingMeta ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Collection tile ───────────────────────────────────────────────────────────

class _CollectionTile extends StatelessWidget {
  final CollectionWithCount collection;
  final bool isSelected;
  final VoidCallback onTap;

  const _CollectionTile({
    required this.collection,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = _parseColor(collection.color) ?? theme.colorScheme.surface;
    final hasImage = collection.coverImage?.isNotEmpty == true;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Card
          Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: hasImage
                        ? Image.file(
                            File(collection.coverImage!),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            color: Colors.black.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.white54,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        collection.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${collection.bookmarkCount} '
                        '${collection.bookmarkCount == 1 ? 'item' : 'items'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selection overlay
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      final buffer = StringBuffer();
      if (hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }
}
