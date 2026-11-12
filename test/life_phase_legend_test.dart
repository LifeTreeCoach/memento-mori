import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/earlier_phases.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/home_screen.dart';

import 'support/compass_test_app.dart';

/// The Pixel 5 end-to-end test (pa_53): birth 1990-03-15, earlier phases
/// Kindheit (0), Schule (6), Studium (19), then "Aufbauphase" since
/// September 2022, closed today into "Umbruch" (planned for two years).
final DateTime _birth = DateTime(1990, 3, 15);
final DateTime _today = DateTime(2026, 11, 7);

Future<void> _seedPhases() async {
  final buildUp = await CompassService.startPhase(
      preset: PhasePreset.buildUp, start: DateTime(2022, 9, 7), today: _today);
  for (final (preset, age) in [
    (PhasePreset.study, 19),
    (PhasePreset.school, 6),
    (PhasePreset.childhood, 0),
  ]) {
    await CompassService.startPhase(
        preset: preset, start: startAtAge(_birth, age), today: _today);
  }
  await CompassService.closePhase(
    closingId: buildUp.id,
    next: LifePhase(
      id: 'umbruch',
      preset: PhasePreset.transition,
      start: _today,
      plannedEnd: DateTime(2028, 11, 7),
    ),
    carryOver: const {},
    letGo: const {},
    today: _today,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('weeks mode lists every phase in the legend (pa_53)',
      (tester) async {
    await initCompassTest(lang: 'de', extra: {
      'birth_date': _birth.toIso8601String(),
      'display_mode': 'weeks',
    });
    await _seedPhases();
    await pumpCompassApp(tester, HomeScreen(now: _today),
        size: const Size(393, 851));

    final legend = find.byKey(const ValueKey('phase_legend'));
    final labels = tester
        .widgetList<Text>(find.descendant(of: legend, matching: find.byType(Text)))
        .map((t) => t.data)
        .toList();
    expect(labels, [
      'Kindheit 0–6',
      'Schule 6–19',
      'Studium 19–32',
      'Aufbauphase 32–36',
      'Umbruch 36–heute',
      'geplant',
    ]);
    // At 393dp the legend wraps; the earliest phases sit in rows above
    // "Aufbauphase", so scrolling the tab by a row hides them under the
    // status bar (as in the screenshot).
    double top(String label) => tester.getRect(find.text(label)).top;
    expect(top('Kindheit 0–6'), lessThan(top('Aufbauphase 32–36')));
    // Every entry is laid out on screen, not cut off.
    final screen = Offset.zero & tester.view.physicalSize / 3;
    for (final label in labels) {
      final rect = tester.getRect(find.text(label!));
      expect(screen.contains(rect.topLeft) && screen.contains(rect.bottomRight),
          isTrue, reason: '$label at $rect');
    }
  });
}
