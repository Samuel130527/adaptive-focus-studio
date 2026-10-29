import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_focus_studio/models/focus_session.dart';
import 'package:adaptive_focus_studio/utils/focus_recommendation.dart';

FocusSession session({
  required String startedAt,
  String? endedAt,
  required int actualSeconds,
  String status = 'Completed',
}) {
  return FocusSession(
    presetId: 1,
    presetTitle: 'Test session',
    startedAt: startedAt,
    endedAt: endedAt ?? startedAt,
    actualSeconds: actualSeconds,
    status: status,
  );
}

void main() {
  group('FocusRecommendation.suggestMinutes', () {
    test('uses default duration when there are no sessions', () {
      expect(
        FocusRecommendation.suggestMinutes(sessions: [], defaultMinutes: 40),
        40,
      );
    });

    test('clamps default duration to the allowed range', () {
      expect(
        FocusRecommendation.suggestMinutes(sessions: [], defaultMinutes: 2),
        5,
      );
      expect(
        FocusRecommendation.suggestMinutes(sessions: [], defaultMinutes: 200),
        120,
      );
    });

    test('averages completed sessions and rounds to nearest five minutes', () {
      final sessions = [
        session(startedAt: '2026-10-21T10:00:00', actualSeconds: 20 * 60),
        session(startedAt: '2026-10-20T10:00:00', actualSeconds: 30 * 60),
      ];

      expect(
        FocusRecommendation.suggestMinutes(
          sessions: sessions,
          defaultMinutes: 25,
        ),
        25,
      );
    });

    test('ignores unfinished or zero-duration sessions', () {
      final sessions = [
        session(startedAt: '2026-10-21T10:00:00', actualSeconds: 10 * 60),
        session(
          startedAt: '2026-10-21T09:00:00',
          actualSeconds: 100 * 60,
          status: 'Finished early',
        ),
        session(
          startedAt: '2026-10-21T08:00:00',
          actualSeconds: 0,
        ),
      ];

      expect(
        FocusRecommendation.suggestMinutes(
          sessions: sessions,
          defaultMinutes: 40,
        ),
        10,
      );
    });

    test('uses only the five most recent completed sessions', () {
      final sessions = [
        session(startedAt: '2026-10-21T12:00:00', actualSeconds: 10 * 60),
        session(startedAt: '2026-10-20T12:00:00', actualSeconds: 10 * 60),
        session(startedAt: '2026-10-19T12:00:00', actualSeconds: 10 * 60),
        session(startedAt: '2026-10-18T12:00:00', actualSeconds: 10 * 60),
        session(startedAt: '2026-10-17T12:00:00', actualSeconds: 10 * 60),
        session(startedAt: '2026-10-16T12:00:00', actualSeconds: 100 * 60),
      ];

      expect(
        FocusRecommendation.suggestMinutes(
          sessions: sessions,
          defaultMinutes: 25,
        ),
        10,
      );
    });
    
    test('clamps a short completed-session recommendation to five minutes', () {
      final sessions = [
        session(startedAt: '2026-10-21T10:00:00', actualSeconds: 2 * 60),
      ];

      expect(
        FocusRecommendation.suggestMinutes(
          sessions: sessions,
          defaultMinutes: 40,
        ),
        5,
      );
    });

    test('clamps a long completed-session recommendation to 120 minutes', () {
      final sessions = [
        session(startedAt: '2026-10-21T10:00:00', actualSeconds: 150 * 60),
      ];

      expect(
        FocusRecommendation.suggestMinutes(
          sessions: sessions,
          defaultMinutes: 40,
        ),
        120,
      );
    });

    test('rounds the average of completed sessions to five minutes', () {
      final sessions = [
        session(startedAt: '2026-10-21T10:00:00', actualSeconds: 20 * 60),
        session(startedAt: '2026-10-20T10:00:00', actualSeconds: 27 * 60),
      ];

      expect(
        FocusRecommendation.suggestMinutes(
          sessions: sessions,
          defaultMinutes: 40,
        ),
        25,
      );
    });

    test('uses default duration when no sessions are valid', () {
      final sessions = [
        session(
          startedAt: '2026-10-21T10:00:00',
          actualSeconds: 0,
        ),
        session(
          startedAt: '2026-10-20T10:00:00',
          actualSeconds: 50 * 60,
          status: 'Finished early',
        ),
      ];

      expect(
        FocusRecommendation.suggestMinutes(
          sessions: sessions,
          defaultMinutes: 40,
        ),
        40,
      );
    });
  });
}
