// lib/features/bookmarks/pages/save_shared_link_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bookmark_model.dart';
import '../../collections/widgets/collection_card.dart';
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

  Future<void> _openAddCollection() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddCollectionSheet(),
    );
    ref.invalidate(collectionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
  final collectionsAsync = ref.watch(filteredCollectionsProvider);
  
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Save link')),
      // FAB eliminado — el botón + se mueve junto al buscador
      body: Column(
        children: [
          // ── Collections picker ───────────────────────────────────────────
          Expanded(
            child: collectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No collections yet.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _openAddCollection,
                          icon: const Icon(Icons.add),
                          label: const Text('Create one'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Search + botón añadir
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
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
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _openAddCollection,
                            icon: const Icon(Icons.add),
                            tooltip: 'New collection',
                          ),
                        ],
                      ),
                    ),

                    // Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                          return CollectionCard(
                            id: col.id!,
                            name: col.name,
                            colorHex: col.color,
                            imagePath: col.coverImage,
                            isSelected: isSelected,
                            bookmarkCount: col.bookmarkCount,
                            onTap: () => setState(() {
                              _selectedCollectionId =
                                  isSelected ? null : col.id;
                            }),
                            // onLongPress omitido intencionalmente:
                            // en esta pantalla no aplica edición/borrado
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