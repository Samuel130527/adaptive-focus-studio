
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_focus_studio/models/focus_preset.dart';

void main() {
  group('FocusPreset', () {
    const preset = FocusPreset(
      id: 1,
      title: 'Deep Work',
      category: 'Study',
      targetMinutes: 40,
      notes: 'Keep distractions away',
      createdAt: '2026-10-21T09:00:00',
      updatedAt: '2026-10-21T09:00:00',
    );

    test('toMap includes every field', () {
      final map = preset.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Deep Work');
      expect(map['category'], 'Study');
      expect(map['targetMinutes'], 40);
      expect(map['notes'], 'Keep distractions away');
      expect(map['createdAt'], '2026-10-21T09:00:00');
      expect(map['updatedAt'], '2026-10-21T09:00:00');
    });

    test('fromMap restores every field', () {
      final restored = FocusPreset.fromMap(preset.toMap());

      expect(restored.id, preset.id);
      expect(restored.title, preset.title);
      expect(restored.category, preset.category);
      expect(restored.targetMinutes, preset.targetMinutes);
      expect(restored.notes, preset.notes);
      expect(restored.createdAt, preset.createdAt);
      expect(restored.updatedAt, preset.updatedAt);
    });

    test('copyWith changes selected fields only', () {
      final updated = preset.copyWith(
        title: 'Reading',
        targetMinutes: 25,
      );

      expect(updated.title, 'Reading');
      expect(updated.targetMinutes, 25);
      expect(updated.category, preset.category);
      expect(updated.notes, preset.notes);
      expect(updated.id, preset.id);
    });

    test('copyWith preserves original when called without arguments', () {
      final copy = preset.copyWith();

      expect(copy.toMap(), preset.toMap());
    });
  });
}
