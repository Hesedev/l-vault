// lib/features/collections/widgets/add_collection_sheet.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/collection_providers.dart';
import '../../../data/models/collection_model.dart';

import 'package:path_provider/path_provider.dart';

class AddCollectionSheet extends ConsumerStatefulWidget {
  final CollectionModel? existingCollection;

  const AddCollectionSheet({super.key, this.existingCollection});

  @override
  ConsumerState<AddCollectionSheet> createState() => _AddCollectionSheetState();
}

class _AddCollectionSheetState extends ConsumerState<AddCollectionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // null = color predeterminado del tema (se guarda como null en DB)
  // cualquier otro valor = color personalizado elegido por el usuario
  String? _selectedColor;
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final existing = widget.existingCollection;

    if (existing != null) {
      _nameController.text = existing.name;
      // Si color es null en DB, _selectedColor queda null (predeterminado)
      _selectedColor = existing.color;

      if (existing.coverImage != null) {
        _selectedImage = File(existing.coverImage!);
      }
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
    final savedImage = await File(image.path).copy('${appDir.path}/$fileName');

    setState(() {
      _selectedImage = savedImage;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final repo = ref.read(collectionRepositoryProvider);

    // null = color predeterminado, que en la UI se resolverá como
    // Theme.of(context).colorScheme.surface — siempre adaptado al tema actual
    final colorToSave = _selectedColor;

    if (widget.existingCollection != null) {
      await repo.update(
        widget.existingCollection!.copyWith(
          name: _nameController.text.trim(),
          color: colorToSave,
          coverImage: _selectedImage?.path,
        ),
      );
    } else {
      await repo.insert(
        CollectionModel(
          name: _nameController.text.trim(),
          color: colorToSave,
          coverImage: _selectedImage?.path,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    ref.invalidate(collectionsProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // El primer "color" de la paleta representa el predeterminado del tema.
    // Se muestra visualmente como el color actual del surface, pero se guarda como null.
    final List<String?> colors = [
      null,        // predeterminado — siempre se adapta al tema
      '#FF0000',
      '#C2185B',
      '#3F51B5',
      '#009688',
      '#5D4037',
      '#FFC107',
      '#673AB7',
      '#E64A19',
    ];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existingCollection == null
                    ? "Add collection"
                    : "Edit collection",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 20),

              /// IMAGE PICKER
              Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.camera_alt, size: 28),
                            ),
                    ),
                  ),
                  if (_selectedImage != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            await _selectedImage!.delete();
                          } catch (_) {}
                          setState(() => _selectedImage = null);
                        },
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
                ],
              ),

              const SizedBox(height: 20),

              /// NAME FIELD
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: "Collection name"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Name is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text(
                "Choose Color",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                children: colors.map((colorHex) {
                  // El color visual del círculo: null → surface del tema actual
                  final displayColor = colorHex != null
                      ? _hexToColor(colorHex)
                      : Theme.of(context).colorScheme.surface;

                  final isSelected = _selectedColor == colorHex;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorHex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: displayColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.08),
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
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
                          : const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}