// lib/features/settings/pages/settings_page.dart

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../features/bookmarks/providers/bookmark_providers.dart';
import '../../../features/collections/providers/collection_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ───────────────────────────────────────────────────
          const _SectionHeader(label: 'Appearance'),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            title: 'Theme',
            subtitle: isDark ? 'Dark' : 'Light',
            trailing: Switch(
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
          ),

          const SizedBox(height: 24),

          // ── Data ─────────────────────────────────────────────────────────
          const _SectionHeader(label: 'Data'),
          _SettingsTile(
            icon: Icons.upload_rounded,
            title: 'Export backup',
            subtitle: 'Save all bookmarks and collections as a ZIP file',
            onTap: () => _export(context, ref),
          ),
          _SettingsTile(
            icon: Icons.download_rounded,
            title: 'Import backup',
            subtitle: 'Restore from a previously exported ZIP file',
            onTap: () => _import(context, ref),
          ),
        ],
      ),
    );
  }

  // ── EXPORT ────────────────────────────────────────────────────────────────

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    _showLoadingDialog(context, 'Exporting...');

    try {
      final db = await AppDatabase.database;
      final tempDir = await getTemporaryDirectory();

      // 1. Leer todas las colecciones y bookmarks de la DB
      final collectionMaps = await db.query('collection');
      final bookmarkMaps = await db.query('bookmark');

      // 2. Construir el JSON — las imágenes locales se referencian por nombre
      //    de archivo dentro de la carpeta images/ del ZIP
      final collections = <Map<String, dynamic>>[];
      final bookmarks = <Map<String, dynamic>>[];

      // Mapa de path local → nombre de archivo dentro del ZIP
      // Así si dos registros tienen la misma imagen, no la duplicamos
      final imageFiles = <String, String>{}; // {localPath: 'images/abc.jpg'}

      for (final c in collectionMaps) {
        final result = Map<String, dynamic>.from(c);
        final coverPath = c['cover_image'] as String?;
        if (coverPath != null && !coverPath.startsWith('http')) {
          final zipName = _registerImage(coverPath, imageFiles);
          result['cover_image'] = zipName; // e.g. "images/cover_1.jpg"
        }
        collections.add(result);
      }

      for (final b in bookmarkMaps) {
        final result = Map<String, dynamic>.from(b);
        final imagePath = b['image'] as String?;
        if (imagePath != null && !imagePath.startsWith('http')) {
          final zipName = _registerImage(imagePath, imageFiles);
          result['image'] = zipName;
        }
        bookmarks.add(result);
      }

      // 3. Serializar el JSON
      final backup = {
        'exported_at': DateTime.now().toIso8601String(),
        'version': 1,
        'collections': collections,
        'bookmarks': bookmarks,
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      // 4. Construir el archivo ZIP en memoria
      final archive = Archive();

      // Agregar backup.json al ZIP
      final jsonBytes = utf8.encode(jsonString);
      archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));

      // Agregar cada imagen local al ZIP dentro de images/
      for (final entry in imageFiles.entries) {
        final localPath = entry.key;   // path real en el dispositivo
        final zipPath = entry.value;   // "images/nombre.jpg" dentro del ZIP
        final file = File(localPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
        }
      }

      // 5. Escribir el ZIP en un archivo temporal
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final zipPath = '${tempDir.path}/linkvault_backup_$timestamp.zip';
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(ZipEncoder().encode(archive)!);

      // 6. Cerrar loading y guardar directamente en Descargas
      if (context.mounted) Navigator.pop(context);

      final downloadsDir = Directory('/storage/emulated/0/Download');
      final destPath = '${downloadsDir.path}/linkvault_backup_$timestamp.zip';
      await File(zipPath).copy(destPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to Downloads/linkvault_backup_$timestamp.zip'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorSnackbar(context, 'Export failed: $e');
      }
    }
  }

  // Registra una imagen local en el mapa y retorna su nombre dentro del ZIP.
  // Si la imagen ya fue registrada, retorna el nombre existente (sin duplicar).
  String _registerImage(String localPath, Map<String, String> imageFiles) {
    if (imageFiles.containsKey(localPath)) {
      return imageFiles[localPath]!;
    }
    final ext = localPath.contains('.') ? localPath.split('.').last : 'jpg';
    final zipName = 'images/${imageFiles.length + 1}_img.$ext';
    imageFiles[localPath] = zipName;
    return zipName;
  }

  // ── IMPORT ────────────────────────────────────────────────────────────────

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    // 1. Confirmar con el usuario
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import backup'),
        content: const Text(
          'This will replace all your current bookmarks and collections. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. File picker — solo ZIP
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) return;

    if (context.mounted) _showLoadingDialog(context, 'Importing...');

    try {
      // 3. Leer y descomprimir el ZIP en memoria
      final zipBytes = await File(result.files.single.path!).readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // 4. Extraer backup.json del ZIP
      final jsonEntry = archive.findFile('backup.json');
      if (jsonEntry == null) throw Exception('Invalid backup: backup.json not found');

      final jsonString = utf8.decode(jsonEntry.content as List<int>);
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!backup.containsKey('collections') || !backup.containsKey('bookmarks')) {
        throw Exception('Invalid backup file');
      }

      final collections =
          (backup['collections'] as List).cast<Map<String, dynamic>>();
      final bookmarks =
          (backup['bookmarks'] as List).cast<Map<String, dynamic>>();

      // 5. Extraer las imágenes del ZIP al directorio de la app
      //    Guardamos el mapeo zipPath → localPath para luego actualizar
      //    las referencias en colecciones y bookmarks
      final appDir = await getApplicationDocumentsDirectory();
      final zipToLocalPath = <String, String>{}; // {"images/1_img.jpg": "/data/.../abc.jpg"}

      for (final file in archive.files) {
        if (file.isFile && file.name.startsWith('images/')) {
          final bytes = file.content as List<int>;
          final fileName = '${DateTime.now().microsecondsSinceEpoch}_${file.name.split('/').last}';
          final localFile = File('${appDir.path}/$fileName');
          await localFile.writeAsBytes(bytes);
          zipToLocalPath[file.name] = localFile.path;
        }
      }

      // 6. Limpiar DB actual
      final db = await AppDatabase.database;
      await db.delete('bookmark');
      await db.delete('collection');

      // 7. Insertar colecciones con mapeo de IDs
      final collectionIdMap = <int, int>{};

      for (final col in collections) {
        final oldId = col['id'] as int;
        final coverRef = col['cover_image'] as String?;

        // Si la referencia es un path de ZIP, traducirla al path local
        final newCoverPath = (coverRef != null && zipToLocalPath.containsKey(coverRef))
            ? zipToLocalPath[coverRef]
            : coverRef; // URL remota o null

        final newId = await db.insert('collection', {
          'name': col['name'],
          'color': col['color'],
          'cover_image': newCoverPath,
          'created_at': col['created_at'],
        });

        collectionIdMap[oldId] = newId;
      }

      // 8. Insertar bookmarks
      for (final bm in bookmarks) {
        final imageRef = bm['image'] as String?;
        final newImagePath = (imageRef != null && zipToLocalPath.containsKey(imageRef))
            ? zipToLocalPath[imageRef]
            : imageRef;

        final oldCollectionId = bm['collection_id'] as int?;
        final newCollectionId =
            oldCollectionId != null ? collectionIdMap[oldCollectionId] : null;

        await db.insert('bookmark', {
          'title': bm['title'],
          'url': bm['url'],
          'notes': bm['notes'],
          'image': newImagePath,
          'is_favorite': bm['is_favorite'],
          'collection_id': newCollectionId,
          'created_at': bm['created_at'],
        });
      }

      // 9. Refrescar la UI
      ref.invalidate(allBookmarksProvider);
      ref.invalidate(collectionsProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${collections.length} collections '
              'and ${bookmarks.length} bookmarks',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorSnackbar(context, 'Import failed: $e');
      }
    }
  }

  // ── Helpers UI ────────────────────────────────────────────────────────────

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right, color: theme.hintColor)
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}