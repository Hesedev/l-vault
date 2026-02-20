// lib/data/repositories/collection_repository.dart

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/collection_model.dart';
import '../database/db_tables.dart';

class CollectionRepository {
  Future<List<CollectionModel>> getAll() async {
    final db = await AppDatabase.database;
    final result = await db.query(DbTables.collection);

    return result.map((e) => CollectionModel.fromMap(e)).toList();
  }

  Future<int> insert(CollectionModel collection) async {
    final db = await AppDatabase.database;
    return await db.insert(DbTables.collection, collection.toMap());
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.database;
    return await db.delete(
      DbTables.collection,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getBookmarkCount(int collectionId) async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM bookmark WHERE collection_id = ?',
      [collectionId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> update(CollectionModel collection) async {
    final db = await AppDatabase.database;

    final data = collection.toMap();
    data.remove(
      'id',
    ); // quitar el id del update para evitar que se cree un nuevo registro

    return await db.update(
      DbTables.collection,
      data,
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  Future<List<CollectionWithCount>> getAllWithCount() async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery('''
    SELECT c.*, COUNT(b.id) as bookmark_count
    FROM collection c
    LEFT JOIN bookmark b ON b.collection_id = c.id
    GROUP BY c.id
  ''');

    return result.map((map) {
      return CollectionWithCount(
        id: map['id'] as int,
        name: map['name'] as String,
        color: map['color'] as String?,
        coverImage: map['cover_image'] as String?,
        createdAt: map['created_at'] as String,
        bookmarkCount: map['bookmark_count'] as int,
      );
    }).toList();
  }
}
