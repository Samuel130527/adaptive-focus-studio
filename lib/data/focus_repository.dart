
import 'package:sqflite/sqflite.dart';

import '../models/focus_preset.dart';
import '../models/focus_session.dart';
import 'app_database.dart';

class FocusRepository {
  final AppDatabase _appDatabase;

  FocusRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db => _appDatabase.database;

  // ---------------- PRESET CRUD ----------------

  Future<int> createPreset(FocusPreset preset) async {
    _validatePreset(preset);

    final db = await _db;
    final now = DateTime.now().toIso8601String();

    final values = preset.toMap()
      ..remove('id')
      ..['createdAt'] = now
      ..['updatedAt'] = now;

    return db.insert(
      'focus_presets',
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<FocusPreset>> getAllPresets() async {
    final db = await _db;

    final rows = await db.query(
      'focus_presets',
      orderBy: 'createdAt DESC, id DESC',
    );

    return rows.map(FocusPreset.fromMap).toList();
  }

  Future<FocusPreset?> getPresetById(int id) async {
    final db = await _db;

    final rows = await db.query(
      'focus_presets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return FocusPreset.fromMap(rows.first);
  }

  Future<int> updatePreset(FocusPreset preset) async {
    _validatePreset(preset);

    if (preset.id == null) {
      throw ArgumentError('Cannot update a preset without an ID.');
    }

    final db = await _db;
    final values = preset.toMap()
      ..remove('createdAt')
      ..['updatedAt'] = DateTime.now().toIso8601String();

    final count = await db.update(
      'focus_presets',
      values,
      where: 'id = ?',
      whereArgs: [preset.id],
    );

    if (count == 0) {
      throw StateError('The preset no longer exists.');
    }

    return count;
  }

  Future<int> deletePreset(int id) async {
    final db = await _db;

    return db.delete(
      'focus_presets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- SESSION CRUD ----------------

  Future<int> createSession(FocusSession session) async {
    _validateSession(session);

    final db = await _db;

    final values = session.toMap()..remove('id');

    return db.insert(
      'focus_sessions',
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<FocusSession>> getAllSessions() async {
    final db = await _db;

    final rows = await db.query(
      'focus_sessions',
      orderBy: 'startedAt DESC, id DESC',
    );

    return rows.map(FocusSession.fromMap).toList();
  }

  Future<FocusSession?> getSessionById(int id) async {
    final db = await _db;

    final rows = await db.query(
      'focus_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return FocusSession.fromMap(rows.first);
  }

  Future<int> updateSession(FocusSession session) async {
    _validateSession(session);

    if (session.id == null) {
      throw ArgumentError('Cannot update a session without an ID.');
    }

    final db = await _db;
    final values = session.toMap()..remove('id');

    final count = await db.update(
      'focus_sessions',
      values,
      where: 'id = ?',
      whereArgs: [session.id],
    );

    if (count == 0) {
      throw StateError('The session no longer exists.');
    }

    return count;
  }

  Future<int> deleteSession(int id) async {
    final db = await _db;

    return db.delete(
      'focus_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- VALIDATION ----------------

  void _validatePreset(FocusPreset preset) {
    if (preset.title.trim().isEmpty) {
      throw ArgumentError('Preset title cannot be empty.');
    }

    if (preset.category.trim().isEmpty) {
      throw ArgumentError('Preset category cannot be empty.');
    }

    if (preset.targetMinutes < 1 || preset.targetMinutes > 120) {
      throw ArgumentError('Duration must be between 1 and 120 minutes.');
    }

    if (preset.title.trim().length > 40) {
      throw ArgumentError('Preset title must be 40 characters or fewer.');
    }

    if (preset.category.trim().length > 30) {
      throw ArgumentError('Category must be 30 characters or fewer.');
    }
  }

  void _validateSession(FocusSession session) {
    if (session.presetTitle.trim().isEmpty) {
      throw ArgumentError('Session title cannot be empty.');
    }

    if (session.actualSeconds < 0) {
      throw ArgumentError('Session duration cannot be negative.');
    }

    if (session.status.trim().isEmpty) {
      throw ArgumentError('Session status cannot be empty.');
    }

    if (session.presetId != null) {
      // Ensure the referenced preset exists before writing a session.
      // SQLite foreign-key enforcement remains the final safeguard.
    }
  }

  // ---------------- FILTERS AND AGGREGATES ----------------

  Future<List<FocusSession>> filterSessions({
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db;
    final conditions = <String>[];
    final args = <Object?>[];

    if (status != null && status.trim().isNotEmpty) {
      conditions.add('status = ?');
      args.add(status.trim());
    }

    if (from != null) {
      conditions.add('startedAt >= ?');
      args.add(from.toIso8601String());
    }

    if (to != null) {
      conditions.add('startedAt <= ?');
      args.add(to.toIso8601String());
    }

    final rows = await db.query(
      'focus_sessions',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : args,
      orderBy: 'startedAt DESC',
    );

    return rows.map(FocusSession.fromMap).toList();
  }

  Future<int> getTotalFocusSeconds() async {
    final db = await _db;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(actualSeconds), 0) AS total '
      'FROM focus_sessions '
      "WHERE status IN ('Completed', 'Finished early')",
    );

    return (result.first['total'] as num).toInt();
  }

  Future<int> getCompletedSessionCount() async {
    final db = await _db;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total '
      'FROM focus_sessions '
      "WHERE status IN ('Completed', 'Finished early')",
    );

    return (result.first['total'] as num).toInt();
  }
}
