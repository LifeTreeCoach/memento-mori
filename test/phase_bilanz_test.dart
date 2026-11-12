import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_bilanz.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';

Intention _intention(String id, IntentionStatus status, {String? phaseId}) =>
    Intention(
        id: id,
        title: id,
        status: status,
        createdAt: DateTime(2024),
        doneAt: status == IntentionStatus.done ? DateTime(2025) : null,
        letGoAt: status == IntentionStatus.letGo ? DateTime(2025) : null,
        phaseId: phaseId);

Moment _moment(String id, DateTime date) => Moment(id: id, title: id, date: date);

void main() {
  final today = DateTime(2026, 11, 6);
  final data = CompassData(
    phases: [
      LifePhase(id: 'old', start: DateTime(2020, 1, 1)),
      LifePhase(id: 'cur', start: DateTime(2024, 1, 1)),
    ],
    intentions: [
      _intention('done', IntentionStatus.done, phaseId: 'old'),
      _intention('open', IntentionStatus.someday, phaseId: 'old'),
      _intention('gone', IntentionStatus.letGo, phaseId: 'old'),
      _intention('now', IntentionStatus.now, phaseId: 'cur'),
      _intention('free', IntentionStatus.someday),
    ],
    moments: [
      _moment('before', DateTime(2019, 12, 31)),
      _moment('first', DateTime(2020, 1, 1)),
      _moment('last', DateTime(2023, 12, 31)),
      _moment('next', DateTime(2024, 1, 1)),
      _moment('today', DateTime(2026, 11, 6)),
      _moment('future', DateTime(2026, 11, 7)),
    ],
  );
  final spans = resolvePhases(data.phases, today);

  test('splits the intentions of a phase into lived, open and let go', () {
    final bilanz = PhaseBilanz.of(data, spans.first, today);
    expect(bilanz.lived.map((i) => i.id), ['done']);
    expect(bilanz.open.map((i) => i.id), ['open']);
    expect(bilanz.letGo.map((i) => i.id), ['gone']);
  });

  test('moments from the start up to the next phase (exclusive)', () {
    final bilanz = PhaseBilanz.of(data, spans.first, today);
    expect(bilanz.moments.map((m) => m.id), ['first', 'last']);
  });

  test('the current phase includes today, not the future', () {
    final bilanz = PhaseBilanz.of(data, spans.last, today);
    expect(bilanz.open.map((i) => i.id), ['now']);
    expect(bilanz.lived, isEmpty);
    expect(bilanz.moments.map((m) => m.id), ['next', 'today']);
  });
}
