
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:adaptive_focus_studio/models/focus_preset.dart';
import 'package:adaptive_focus_studio/models/focus_session.dart';
import 'package:adaptive_focus_studio/data/focus_repository.dart';
import 'package:adaptive_focus_studio/data/app_database.dart';

void main() {
  late Database database;
  late FocusRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
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
        },
      ),
    );

    repository = FocusRepository(
      appDatabase: AppDatabase.forTesting(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  
  FocusPreset preset({
    int? id,
    String title = 'Deep Work',
    String category = 'Study',
    int targetMinutes = 40,
    String notes = '',
  }) {
    return FocusPreset(
      id: id,
      title: title,
      category: category,
      targetMinutes: targetMinutes,
      notes: notes,
      createdAt: '2026-10-21T09:00:00',
      updatedAt: '2026-10-21T09:00:00',
    );
  }


  FocusSession session({
    int? id,
    int? presetId,
    String title = 'Deep Work',
    int seconds = 2400,
    String status = 'Completed',
  }) {
    return FocusSession(
      id: id,
      presetId: presetId,
      presetTitle: title,
      startedAt: '2026-10-21T10:00:00',
      endedAt: '2026-10-21T10:40:00',
      actualSeconds: seconds,
      status: status,
    );
  }

  test('creates and retrieves a preset', () async {
    final id = await repository.createPreset(preset());

    final saved = await repository.getPresetById(id);

    expect(saved, isNotNull);
    expect(saved!.title, 'Deep Work');
    expect(saved.targetMinutes, 40);
  });

  test('updates a preset', () async {
    final id = await repository.createPreset(preset());

    await repository.updatePreset(
      preset(id: id, title: 'Reading', targetMinutes: 30),
    );

    final saved = await repository.getPresetById(id);

    expect(saved!.title, 'Reading');
    expect(saved.targetMinutes, 30);
  });

  test('deletes a preset', () async {
    final id = await repository.createPreset(preset());

    expect(await repository.deletePreset(id), 1);
    expect(await repository.getPresetById(id), isNull);
  });

  test('rejects an empty preset title', () async {
    expect(
      () => repository.createPreset(preset(title: '   ')),
      throwsArgumentError,
    );
  });

  test('creates and retrieves a session', () async {
    final id = await repository.createSession(session());

    final saved = await repository.getSessionById(id);

    expect(saved, isNotNull);
    expect(saved!.presetTitle, 'Deep Work');
    expect(saved.actualSeconds, 2400);
  });

  test('rejects a negative session duration', () async {
    expect(
      () => repository.createSession(session(seconds: -1)),
      throwsArgumentError,
    );
  });

  test('calculates total focus seconds and completed count', () async {
    await repository.createSession(session(seconds: 2400));
    await repository.createSession(
      session(seconds: 600, status: 'Finished early'),
    );
    await repository.createSession(
      session(seconds: 300, status: 'In Progress'),
    );

    expect(await repository.getTotalFocusSeconds(), 3000);
    expect(await repository.getCompletedSessionCount(), 2);
  });
  
  test('updates an existing session', () async {
    final id = await repository.createSession(session());

    await repository.updateSession(
      session(
        id: id,
        title: 'Reading',
        seconds: 1800,
        status: 'Finished early',
      ),
    );

    final saved = await repository.getSessionById(id);

    expect(saved, isNotNull);
    expect(saved!.presetTitle, 'Reading');
    expect(saved.actualSeconds, 1800);
    expect(saved.status, 'Finished early');
  });

  test('deletes an existing session', () async {
    final id = await repository.createSession(session());

    expect(await repository.deleteSession(id), 1);
    expect(await repository.getSessionById(id), isNull);
  });

  test('filters sessions by status', () async {
    await repository.createSession(session(seconds: 2400));
    await repository.createSession(
      session(seconds: 600, status: 'Finished early'),
    );

    final completed = await repository.filterSessions(
      status: 'Completed',
    );

    expect(completed.length, 1);
    expect(completed.first.status, 'Completed');
  });

  
  test('filters sessions by date range', () async {
    await repository.createSession(session());

    final results = await repository.filterSessions(
      from: DateTime.parse('2026-10-20T00:00:00'),
      to: DateTime.parse('2026-10-22T00:00:00'),
    );

    expect(results.length, 1);
    expect(results.first.actualSeconds, 2400);
  });


  test('returns zero totals when there are no sessions', () async {
    expect(await repository.getTotalFocusSeconds(), 0);
    expect(await repository.getCompletedSessionCount(), 0);
  });

  test('throws when updating a session that does not exist', () async {
    expect(
      () => repository.updateSession(
        session(id: 999, seconds: 1200),
      ),
      throwsStateError,
    );
  });
}
