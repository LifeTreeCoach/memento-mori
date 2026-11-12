import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_meta.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';

/// Counts of kept moments per life area, per decade of life and per life
/// phase, for the warm "Look back" summary (no goals, no comparison).
class LookBack {
  const LookBack({
    required this.byArea,
    required this.byDecade,
    this.byPhase = const [],
  });

  /// Moments per area (null = no area), most first, then in area order.
  final List<(LifeArea?, int)> byArea;

  /// Moments per decade of life (0 = age 0-9, 10 = 10-19, ...), oldest
  /// first; empty without a birth date.
  final List<(int, int)> byDecade;

  /// Moments per life phase, oldest phase first; phases without moments
  /// and moments before the first phase are left out.
  final List<(LifePhase, int)> byPhase;

  /// [phases] from [resolvePhases] (empty: no grouping by phase);
  /// [intentions] let a moment done from an intention count in that
  /// intention's phase ([phaseSpanOfMoment]), as its tile says.
  factory LookBack.of(
    List<Moment> moments, {
    DateTime? birthDate,
    List<PhaseSpan> phases = const [],
    List<Intention> intentions = const [],
  }) {
    return LookBack(
      byArea: _byArea(moments),
      byDecade: birthDate == null ? const [] : _byDecade(moments, birthDate),
      byPhase: _byPhase(moments, phases, intentions),
    );
  }

  static List<(LifePhase, int)> _byPhase(List<Moment> moments,
      List<PhaseSpan> spans, List<Intention> intentions) {
    final counts = <PhaseSpan, int>{};
    for (final moment in moments) {
      final span = phaseSpanOfMoment(moment,
          intentions: intentions, spans: spans);
      if (span != null) counts[span] = (counts[span] ?? 0) + 1;
    }
    return [
      for (final span in spans)
        if (counts[span] case final count?) (span.phase, count),
    ];
  }

  static List<(LifeArea?, int)> _byArea(List<Moment> moments) {
    final counts = <LifeArea?, int>{};
    for (final moment in moments) {
      counts[moment.area] = (counts[moment.area] ?? 0) + 1;
    }
    int order(LifeArea? area) => area?.index ?? LifeArea.values.length;
    return [for (final e in counts.entries) (e.key, e.value)]
      ..sort((a, b) => a.$2 != b.$2 ? b.$2 - a.$2 : order(a.$1) - order(b.$1));
  }

  static List<(int, int)> _byDecade(List<Moment> moments, DateTime birthDate) {
    final counts = <int, int>{};
    for (final moment in moments) {
      final decade = _ageOn(moment.date, birthDate) ~/ 10 * 10;
      counts[decade] = (counts[decade] ?? 0) + 1;
    }
    final decades = counts.keys.toList()..sort();
    return [for (final decade in decades) (decade, counts[decade]!)];
  }

  /// Full years of age on [date]; 0 before the birth date.
  static int _ageOn(DateTime date, DateTime birthDate) {
    final hadBirthday = date.month > birthDate.month ||
        (date.month == birthDate.month && date.day >= birthDate.day);
    final age = date.year - birthDate.year - (hadBirthday ? 0 : 1);
    return age < 0 ? 0 : age;
  }
}
