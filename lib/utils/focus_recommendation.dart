import '../models/focus_session.dart';

/// Calculates an explainable focus-duration suggestion from saved sessions.
///
/// Only positive-duration sessions marked `Completed` are considered.
/// The five most recent completed sessions are averaged and rounded to the
/// nearest five minutes. The result is clamped to 5–120 minutes.
class FocusRecommendation {
  const FocusRecommendation._();

  static int suggestMinutes({
    required List<FocusSession> sessions,
    required int defaultMinutes,
  }) {
    final completed = sessions
        .where((session) =>
            session.status == 'Completed' && session.actualSeconds > 0)
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a.endedAt ?? a.startedAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b.endedAt ?? b.startedAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    if (completed.isEmpty) {
      return defaultMinutes.clamp(5, 120).toInt();
    }

    final recent = completed.take(5);
    final count = recent.length;
    final totalSeconds = recent.fold<int>(
      0,
      (sum, session) => sum + session.actualSeconds,
    );

    final averageMinutes = (totalSeconds / count / 60).round();
    final roundedToFive = ((averageMinutes + 2) ~/ 5) * 5;
    return roundedToFive.clamp(5, 120).toInt();
  }
}
