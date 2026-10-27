
class FocusPreset {
  final int? id;
  final String title;
  final String category;
  final int targetMinutes;
  final String notes;
  final String createdAt;
  final String updatedAt;

  const FocusPreset({
    this.id,
    required this.title,
    required this.category,
    required this.targetMinutes,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'targetMinutes': targetMinutes,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory FocusPreset.fromMap(Map<String, Object?> map) {
    return FocusPreset(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      targetMinutes: map['targetMinutes'] as int,
      notes: map['notes'] as String? ?? '',
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  FocusPreset copyWith({
    int? id,
    String? title,
    String? category,
    int? targetMinutes,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return FocusPreset(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
