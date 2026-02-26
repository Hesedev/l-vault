// lib/features/bookmarks/widgets/add_bookmark_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── Fetch Open Graph metadata (add mode) ───────────────────────────────────
  Future<void> _fetchMetadata() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isFetchingMeta = true);
    final meta = await MetadataService().fetch(url);

    if (mounted) {
      setState(() {
        _isFetchingMeta = false;
        if (meta.title != null && meta.title!.isNotEmpty) {
          _titleController.text = meta.title!;
        }
        if (meta.imageUrl != null &&
            _selectedImage == null &&
            _remoteImageUrl == null) {
          _remoteImageUrl = meta.imageUrl;
        }
      });
    }
  }

  // ─── Image picker (edit mode only) ──────────────────────────────────────────
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

  // ─── Fallback title from URL host ───────────────────────────────────────────
  String _fallbackTitle(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  // ─── Save ────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final repo = ref.read(bookmarkRepositoryProvider);
    final rawUrl = _urlController.text.trim();
    String imageToSave = _selectedImage?.path ?? _remoteImageUrl ?? '';

    if (_isEditing) {
      // In edit mode the user sets the title manually; use fallback if empty.
      final title = _titleController.text.trim().isEmpty
          ? _fallbackTitle(rawUrl)
          : _titleController.text.trim();

      await repo.update(
        widget.existingBookmark!.copyWith(
          url: rawUrl,
          title: title,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          image: imageToSave.isEmpty ? null : imageToSave,
        ),
      );
    } else {
      // In add mode, auto-fetch metadata if it hasn't been fetched yet.
      String resolvedTitle = _titleController.text.trim();
      String? resolvedImage = _remoteImageUrl;

      if (resolvedTitle.isEmpty && !_isFetchingMeta) {
        final meta = await MetadataService().fetch(rawUrl);
        resolvedTitle = (meta.title != null && meta.title!.isNotEmpty)
            ? meta.title!
            : _fallbackTitle(rawUrl);
        resolvedImage ??= meta.imageUrl;
      } else if (resolvedTitle.isEmpty) {
        resolvedTitle = _fallbackTitle(rawUrl);
      }

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
    if (widget.collectionId != null) {
      ref.invalidate(bookmarksByCollectionProvider(widget.collectionId));
    }

    if (mounted) Navigator.pop(context);
  }

  // ─── Delete (edit mode only) ─────────────────────────────────────────────────
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
    if (widget.collectionId != null) {
      ref.invalidate(bookmarksByCollectionProvider(widget.collectionId));
    }
    if (mounted) Navigator.pop(context);
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
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
          color: const Color(0xFF282828),
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
                // ── Header ─────────────────────────────────────────────────
                Text(
                  _isEditing ? 'Edit bookmark' : 'Add bookmark',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // ══════════════════════════════════════════════════════════
                // EDIT MODE — image picker + title field shown
                // ══════════════════════════════════════════════════════════
                if (_isEditing) ...[
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF404040),
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
                                          errorBuilder: (_, __, ___) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white54,
                                                  size: 28,
                                                ),
                                              ),
                                        ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white54,
                                    size: 28,
                                  ),
                                ),
                        ),
                      ),

                      // Clear image
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

                      // Delete bookmark
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

                  // Title — editable in edit mode
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),

                  const SizedBox(height: 12),
                ],

                // ══════════════════════════════════════════════════════════
                // BOTH MODES — URL field
                // ══════════════════════════════════════════════════════════
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  // Auto-fetch when leaving field (add mode only)
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
                        // Manual fetch button visible in add mode only
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

                // ══════════════════════════════════════════════════════════
                // BOTH MODES — Notes field
                // ══════════════════════════════════════════════════════════
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Add a note (optional)',
                  ),
                ),

                const SizedBox(height: 24),

                // ── Buttons ────────────────────────────────────────────────
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
