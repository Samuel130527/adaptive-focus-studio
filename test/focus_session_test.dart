
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_focus_studio/models/focus_session.dart';

void main() {
  group('FocusSession', () {
    test('toMap includes all session fields', () {
      const session = FocusSession(
        id: 1,
        presetId: 2,
        presetTitle: 'Deep Work',
        startedAt: '2026-10-21T10:00:00',
        endedAt: '2026-10-21T10:40:00',
        actualSeconds: 2400,
        status: 'Completed',
        reflection: 'Good concentration',
      );

      final map = session.toMap();

      expect(map['id'], 1);
      expect(map['presetId'], 2);
      expect(map['presetTitle'], 'Deep Work');
      expect(map['startedAt'], '2026-10-21T10:00:00');
      expect(map['endedAt'], '2026-10-21T10:40:00');
      expect(map['actualSeconds'], 2400);
      expect(map['status'], 'Completed');
      expect(map['reflection'], 'Good concentration');
    });

    test('fromMap restores all session fields', () {
      final map = <String, Object?>{
        'id': 1,
        'presetId': 2,
        'presetTitle': 'Deep Work',
        'startedAt': '2026-10-21T10:00:00',
        'endedAt': '2026-10-21T10:40:00',
        'actualSeconds': 2400,
        'status': 'Completed',
        'reflection': 'Good concentration',
      };

      final session = FocusSession.fromMap(map);

      expect(session.id, 1);
      expect(session.presetId, 2);
      expect(session.presetTitle, 'Deep Work');
      expect(session.startedAt, '2026-10-21T10:00:00');
      expect(session.endedAt, '2026-10-21T10:40:00');
      expect(session.actualSeconds, 2400);
      expect(session.status, 'Completed');
      expect(session.reflection, 'Good concentration');
    });

    test('fromMap defaults missing reflection to an empty string', () {
      final map = <String, Object?>{
        'id': null,
        'presetId': null,
        'presetTitle': 'Quick Focus',
        'startedAt': '2026-10-21T10:00:00',
        'endedAt': null,
        'actualSeconds': 300,
        'status': 'Completed',
      };

      final session = FocusSession.fromMap(map);

      expect(session.reflection, '');
      expect(session.endedAt, isNull);
      expect(session.presetId, isNull);
    });

    test('toMap and fromMap preserve a session with nullable fields', () {
      const original = FocusSession(
        presetTitle: 'Quick Focus',
        startedAt: '2026-10-21T10:00:00',
        endedAt: null,
        actualSeconds: 300,
        status: 'In Progress',
      );

      final restored = FocusSession.fromMap(original.toMap());

      expect(restored.id, isNull);
      expect(restored.presetId, isNull);
      expect(restored.endedAt, isNull);
      expect(restored.reflection, '');
      expect(restored.presetTitle, original.presetTitle);
      expect(restored.actualSeconds, original.actualSeconds);
      expect(restored.status, original.status);
    });
  });
}
