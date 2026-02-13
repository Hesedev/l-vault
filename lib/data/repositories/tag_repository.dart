import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/tag_model.dart';

class TagRepository {
  Future<List<TagModel>> getAll() async {
    final db = await AppDatabase.database;
    final result = await db.query(DbTables.tag);

    return result.map((e) => TagModel.fromMap(e)).toList();
  }

  Future<int> insert(TagModel tag) async {
    final db = await AppDatabase.database;
    return await db.insert(DbTables.tag, tag.toMap());
  }
}
