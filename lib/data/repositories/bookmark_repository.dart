// lib/data/repositories/bookmark_repository.dart

import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/bookmark_model.dart';

class BookmarkRepository {
  Future<List<BookmarkModel>> getAll() async {
    final db = await AppDatabase.database;
    final result = await db.query(
      DbTables.bookmark,
      orderBy: 'created_at DESC',
    );
    return result.map((e) => BookmarkModel.fromMap(e)).toList();
  }

  Future<List<BookmarkModel>> getByCollection(int? collectionId) async {
    final db = await AppDatabase.database;

    final result = await db.query(
      DbTables.bookmark,
      where: collectionId == null ? null : 'collection_id = ?',
      whereArgs: collectionId == null ? null : [collectionId],
      orderBy: 'created_at DESC',
    );

    return result.map((e) => BookmarkModel.fromMap(e)).toList();
  }

  Future<int> insert(BookmarkModel bookmark) async {
    final db = await AppDatabase.database;
    return await db.insert(DbTables.bookmark, bookmark.toMap());
  }

  Future<int> update(BookmarkModel bookmark) async {
    final db = await AppDatabase.database;
    final data = bookmark.toMap();
    data.remove('id');
    return await db.update(
      DbTables.bookmark,
      data,
      where: 'id = ?',
      whereArgs: [bookmark.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.database;
    return await db.delete(DbTables.bookmark, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleFavorite(BookmarkModel bookmark) async {
    final db = await AppDatabase.database;
    final newValue = bookmark.isFavorite == 1 ? 0 : 1;
    return await db.update(
      DbTables.bookmark,
      {'is_favorite': newValue},
      where: 'id = ?',
      whereArgs: [bookmark.id],
    );
  }
}
