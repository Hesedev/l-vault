// lib/data/database/app_database.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _database;

  AppDatabase._();

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'linkvault.db');

    return await openDatabase(
      path,
      version: 2, // ← subido de 1 a 2
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  // =============================
  // CREACIÓN DE TABLAS
  // =============================

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE collection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT,
        cover_image TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmark (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        url TEXT NOT NULL,
        notes TEXT,
        image TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0 CHECK(is_favorite IN (0,1)),
        collection_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
        FOREIGN KEY(collection_id) REFERENCES collection(id)
        ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_bookmark_collection ON bookmark(collection_id)',
    );

    await db.execute(
      'CREATE INDEX idx_bookmark_favorite ON bookmark(is_favorite)',
    );
  }

  // =============================
  // UTILIDADES
  // =============================

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  static Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'linkvault.db');
    await deleteDatabase(path);
    _database = null;
  }
}