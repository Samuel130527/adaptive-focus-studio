
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  AppDatabase.forTesting(this._database);

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'adaptive_focus_studio.db');

    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );

    return _database!;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE focus_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL CHECK(length(trim(title)) > 0),
        category TEXT NOT NULL CHECK(length(trim(category)) > 0),
        targetMinutes INTEGER NOT NULL
          CHECK(targetMinutes BETWEEN 1 AND 120),
        notes TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        presetId INTEGER,
        presetTitle TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        endedAt TEXT,
        actualSeconds INTEGER NOT NULL CHECK(actualSeconds >= 0),
        status TEXT NOT NULL,
        reflection TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (presetId)
          REFERENCES focus_presets(id)
          ON DELETE SET NULL
      )
    ''');
  }
}
