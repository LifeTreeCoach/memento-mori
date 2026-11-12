import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';

void main() {
  final phase = LifePhase(
    id: 'p1',
    preset: PhasePreset.careerStart,
    start: DateTime(2024, 9, 1, 15, 30),
    plannedEnd: DateTime(2027, 6, 30),
    note: 'Good people',
  );

  group('PhasePreset', () {
    test('tryParse by name, null for unknown values', () {
      for (final preset in PhasePreset.values) {
        expect(PhasePreset.tryParse(preset.name), preset);
      }
      for (final value in [null, 42, '', 'retirement']) {
        expect(PhasePreset.tryParse(value), isNull, reason: '$value');
      }
    });

    test('onboarding offers study to calmer, not childhood or school', () {
      expect(PhasePreset.onboarding.first, PhasePreset.study);
      expect(PhasePreset.onboarding.last, PhasePreset.calmer);
      expect(PhasePreset.onboarding, hasLength(6));
      expect(PhasePreset.onboarding,
          isNot(contains(anyOf(PhasePreset.childhood, PhasePreset.school))));
    });
  });

  group('LifePhase', () {
    test('dates are date only', () {
      expect(phase.start, DateTime(2024, 9, 1));
    });

    test('JSON round trip keeps every field, dates as yyyy-MM-dd', () {
      final json = jsonDecode(jsonEncode(phase.toJson())) as Map<String, dynamic>;
      expect(json, {
        'id': 'p1',
        'name': '',
        'presetId': 'careerStart',
        'start': '2024-09-01',
        'plannedEnd': '2027-06-30',
        'note': 'Good people',
      });
      final back = LifePhase.fromJson(json);
      expect(back.id, 'p1');
      expect(back.name, '');
      expect(back.preset, PhasePreset.careerStart);
      expect(back.start, DateTime(2024, 9, 1));
      expect(back.plannedEnd, DateTime(2027, 6, 30));
      expect(back.note, 'Good people');
    });

    test('optional fields are left out; a custom name is kept', () {
      final own = LifePhase(id: 'p2', name: 'Sabbatical', start: DateTime(2026));
      expect(own.toJson().keys, ['id', 'name', 'start']);
      expect(LifePhase.fromJson(own.toJson()).name, 'Sabbatical');
    });

    test('unknown or broken optional fields are dropped', () {
      final parsed = LifePhase.fromJson({
        'id': 'p',
        'name': 3,
        'presetId': 'bogus',
        'start': '2020-01-01',
        'plannedEnd': 'soon',
        'note': ' ',
      });
      expect(parsed.name, '');
      expect(parsed.preset, isNull);
      expect(parsed.plannedEnd, isNull);
      expect(parsed.note, isNull);
    });

    test('entries without id or start are rejected', () {
      expect(() => LifePhase.fromJson({'start': '2020-01-01'}), throwsFormatException);
      expect(() => LifePhase.fromJson({'id': 'p'}), throwsFormatException);
      expect(() => LifePhase.fromJson({'id': 'p', 'start': 'x'}), throwsFormatException);
    });

    test('copyWith replaces fields and clears plannedEnd and note', () {
      final moved = phase.copyWith(start: DateTime(2024, 10, 1), name: 'Job');
      expect(moved.start, DateTime(2024, 10, 1));
      expect(moved.name, 'Job');
      expect(moved.plannedEnd, phase.plannedEnd);
      expect(moved.note, phase.note);
      final cleared = phase.copyWith(clearPlannedEnd: true, clearNote: true);
      expect(cleared.plannedEnd, isNull);
      expect(cleared.note, isNull);
      expect(cleared.id, 'p1');
      expect(cleared.preset, PhasePreset.careerStart);
    });
  });
}
