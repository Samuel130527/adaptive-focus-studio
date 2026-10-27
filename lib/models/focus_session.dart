
class FocusSession {
  final int? id;
  final int? presetId;
  final String presetTitle;
  final String startedAt;
  final String? endedAt;
  final int actualSeconds;
  final String status;
  final String reflection;

  const FocusSession({
    this.id,
    this.presetId,
    required this.presetTitle,
    required this.startedAt,
    this.endedAt,
    required this.actualSeconds,
    required this.status,
    this.reflection = '',
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'presetId': presetId,
      'presetTitle': presetTitle,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'actualSeconds': actualSeconds,
      'status': status,
      'reflection': reflection,
    };
  }

  factory FocusSession.fromMap(Map<String, Object?> map) {
    return FocusSession(
      id: map['id'] as int?,
      presetId: map['presetId'] as int?,
      presetTitle: map['presetTitle'] as String,
      startedAt: map['startedAt'] as String,
      endedAt: map['endedAt'] as String?,
      actualSeconds: map['actualSeconds'] as int,
      status: map['status'] as String,
      reflection: map['reflection'] as String? ?? '',
    );
  }
}
