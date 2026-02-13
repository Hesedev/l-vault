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
}
