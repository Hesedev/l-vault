// lib/features/bookmarks/widgets/add_bookmark_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkvault/features/collections/providers/collection_providers.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/models/bookmark_model.dart';
import '../../../services/metadata_service.dart';
import '../providers/bookmark_providers.dart';

class AddBookmarkDialog extends ConsumerStatefulWidget {
  final BookmarkModel? existingBookmark;
  final int? collectionId;

  const AddBookmarkDialog({
    super.key,
    this.existingBookmark,
    this.collectionId,
  });

  @override
  ConsumerState<AddBookmarkDialog> createState() => _AddBookmarkDialogState();
}

class _AddBookmarkDialogState extends ConsumerState<AddBookmarkDialog> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _remoteImageUrl;
  bool _isSaving = false;
  bool _isFetchingMeta = false;
  bool _metaFetched = false;

  bool get _isEditing => widget.existingBookmark != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBookmark;
    if (existing != null) {
      _urlController.text = existing.url;
      _titleController.text = existing.title ?? '';
      _notesController.text = existing.notes ?? '';
      if (existing.image != null) {
        if (existing.image!.startsWith('http')) {
          _remoteImageUrl = existing.image;
        } else {
          _selectedImage = File(existing.image!);
        }
      }
      _metaFetched = true;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _hostnameOf(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  Future<void> _fetchMetadata() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isFetchingMeta = true);

    final meta = await MetadataService().fetch(url);

    if (mounted) {
      setState(() {
        _isFetchingMeta = false;
        _metaFetched = true;
        if (meta.title != null) _titleController.text = meta.title!;
        if (meta.imageUrl != null &&
            _selectedImage == null &&
            _remoteImageUrl == null) {
          _remoteImageUrl = meta.imageUrl;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(image.path).copy('${appDir.path}/$fileName');

    setState(() {
      _selectedImage = saved;
      _remoteImageUrl = null;
    });
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _remoteImageUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final repo = ref.read(bookmarkRepositoryProvider);
    final rawUrl = _urlController.text.trim();

    if (_isEditing) {
      final title = _titleController.text.trim().isEmpty
          ? _hostnameOf(rawUrl)
          : _titleController.text.trim();

      await repo.update(
        widget.existingBookmark!.copyWith(
          url: rawUrl,
          title: title,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          image: _selectedImage?.path ?? _remoteImageUrl,
        ),
      );
    } else {
      String? resolvedTitle = _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim();
      String? resolvedImage = _remoteImageUrl;

      if (!_metaFetched) {
        final meta = await MetadataService().fetch(rawUrl);
        resolvedTitle ??= meta.title;
        resolvedImage ??= meta.imageUrl;
      }

      // Guaranteed fallback — hostname is always available
      resolvedTitle ??= _hostnameOf(rawUrl);

      await repo.insert(
        BookmarkModel(
          url: rawUrl,
          title: resolvedTitle,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          image: resolvedImage,
          collectionId: widget.collectionId,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    ref.invalidate(allBookmarksProvider);
    ref.invalidate(collectionsProvider);
    if (widget.collectionId != null) {
      ref.invalidate(bookmarksByCollectionProvider(widget.collectionId));
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete bookmark?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final repo = ref.read(bookmarkRepositoryProvider);
    await repo.delete(widget.existingBookmark!.id!);
    ref.invalidate(allBookmarksProvider);
    ref.invalidate(collectionsProvider);

    if (widget.collectionId != null) {
      ref.invalidate(bookmarksByCollectionProvider(widget.collectionId));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasImage = _selectedImage != null || _remoteImageUrl != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color:  Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit bookmark' : 'Add bookmark',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // ── EDIT MODE: image + title ────────────────────────────────
                if (_isEditing) ...[
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:  Theme.of(context).inputDecorationTheme.fillColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: hasImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        )
                                      : Image.network(
                                          _remoteImageUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (_, _, _) =>
                                              Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  size: 28,
                                                ),
                                              ),
                                        ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 28,
                                  ),
                                ),
                        ),
                      ),
                      if (hasImage)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: _clearImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: GestureDetector(
                          onTap: _delete,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── BOTH MODES: URL ─────────────────────────────────────────
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  onEditingComplete: _isEditing ? null : _fetchMetadata,
                  decoration: InputDecoration(
                    hintText: 'URL',
                    suffixIcon: _isFetchingMeta
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : !_isEditing
                        ? IconButton(
                            icon: const Icon(
                              Icons.auto_fix_high_rounded,
                              size: 20,
                            ),
                            tooltip: 'Fetch metadata',
                            onPressed: _fetchMetadata,
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'URL is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // ── BOTH MODES: Notes ───────────────────────────────────────
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Add a note (optional)',
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.onSurface.withOpacity(0.08),
                          foregroundColor: colors.onSurface.withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
