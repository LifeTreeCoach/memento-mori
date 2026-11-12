import 'package:memento_mori_life_in_weeks/compass/compass_prompt.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompts.dart';
import 'package:memento_mori_life_in_weeks/life/life_stage.dart';

/// Monday the week count starts from; week 0 is the week of this day.
final DateTime compassEpochMonday = DateTime.utc(2024, 1, 1);

/// Age assumed for the question pool while no birth date is set (Compass
/// tab and weekly reflection notification).
const double compassDefaultAgeYears = 35;

/// Weeks between [compassEpochMonday] and the Monday-to-Sunday week of
/// [date] (negative before it). Never resets at the turn of a year.
int compassWeekIndex(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final days = day.difference(compassEpochMonday).inDays;
  return _floorDiv(days, 7);
}

/// ISO 8601 week of [date], e.g. `2026-W45` (the year is the ISO week year).
String isoWeekKey(DateTime date) {
  final (:year, :week) = isoWeekOf(date);
  return '$year-W${week.toString().padLeft(2, '0')}';
}

/// ISO 8601 week year and week number (1-53) of [date]: the week runs
/// Monday to Sunday and belongs to the year of its Thursday.
({int year, int week}) isoWeekOf(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final week = (thursday.difference(DateTime.utc(thursday.year)).inDays ~/ 7) + 1;
  return (year: thursday.year, week: week);
}

/// Weeks before and after a swapped week whose questions the swapped
/// prompt never repeats.
const int compassSwapDistinctWeeks = 4;

/// The question of the week of [date] for someone [ageYears] old.
///
/// Deterministic per week. Rhythm: even weeks ask courage, odd weeks cycle
/// connection, rest, pride; with [gentleOnly] every week cycles the gentle
/// kinds. Prompts are limited to the life stage of [ageYears]. A non-zero
/// [swap] gives a gentle prompt (never courage) that differs from the
/// unswapped question of every week within [compassSwapDistinctWeeks].
///
/// Phase questions (their text contains `{phase}`) are asked only with
/// [hasPhase], i.e. while a life phase is lived: then every other turn of
/// a kind asks one of its phase questions. Without [hasPhase] the result
/// never is a phase question.
CompassPrompt questionForWeek(
  DateTime date, {
  required double ageYears,
  required bool gentleOnly,
  int swap = 0,
  bool hasPhase = false,
}) {
  final week = compassWeekIndex(date);
  final rules = _Rules(
    LifeStage.fromAge(ageYears.floor()),
    gentleOnly,
    hasPhase,
  );
  final own = _questionOfWeek(week, rules);
  if (swap == 0) return own;
  return _swappedQuestion(week, rules, own, swap);
}

/// What a week's question depends on besides the week itself.
class _Rules {
  const _Rules(this.stage, this.gentleOnly, this.hasPhase);

  final LifeStage stage;
  final bool gentleOnly;
  final bool hasPhase;
}

/// The unswapped question of [week] (see [questionForWeek]).
CompassPrompt _questionOfWeek(int week, _Rules rules) {
  const gentle = CompassPromptKind.gentle;
  final CompassPromptKind kind;
  final int occurrence;
  if (rules.gentleOnly) {
    occurrence = _floorDiv(week, gentle.length);
    kind = gentle[week % gentle.length];
  } else if (week.isEven) {
    occurrence = _floorDiv(week, 2);
    kind = CompassPromptKind.courage;
  } else {
    // Odd weeks: the gentle kind of this pair of weeks.
    final pair = _floorDiv(week, 2);
    occurrence = _floorDiv(pair, gentle.length);
    kind = gentle[pair % gentle.length];
  }
  if (rules.hasPhase && occurrence.isOdd) {
    final phasePool = _phasePool(kind, rules.stage);
    if (phasePool.isNotEmpty) {
      return phasePool[_floorDiv(occurrence, 2) % phasePool.length];
    }
  }
  final pool = _pool(kind, rules.stage);
  return pool[occurrence % pool.length];
}

/// A gentle prompt for [week] other than the unswapped questions of the
/// weeks around it: another gentle kind than [own] first, starting half a
/// pool away from this week's position, the first prompt not taken.
/// With a phase, the phase questions of a kind are candidates as well.
CompassPrompt _swappedQuestion(
  int week,
  _Rules rules,
  CompassPrompt own,
  int swap,
) {
  final taken = {
    for (
      var w = week - compassSwapDistinctWeeks;
      w <= week + compassSwapDistinctWeeks;
      w++
    )
      _questionOfWeek(w, rules).id,
  };
  const gentle = CompassPromptKind.gentle;
  final ownIndex = gentle.indexOf(own.kind);
  final firstKind = ownIndex < 0 ? week + swap - 1 : ownIndex + swap;
  for (var k = 0; k < gentle.length; k++) {
    final kind = gentle[(firstKind + k) % gentle.length];
    final pool = [
      ..._pool(kind, rules.stage),
      if (rules.hasPhase) ..._phasePool(kind, rules.stage),
    ];
    final start = _floorDiv(week, 2) + pool.length ~/ 2;
    for (var i = 0; i < pool.length; i++) {
      final candidate = pool[(start + i) % pool.length];
      if (!taken.contains(candidate.id)) return candidate;
    }
  }
  // Unreachable with the shipped pools; still never the week's own question.
  return compassQuestions.firstWhere(
    (p) =>
        p.kind != CompassPromptKind.courage &&
        p.id != own.id &&
        (rules.hasPhase || !p.phase),
  );
}

/// Questions of [kind] without phase questions for [stage]; all of them if
/// none fits.
List<CompassPrompt> _pool(CompassPromptKind kind, LifeStage stage) {
  final ofKind = compassQuestions
      .where((p) => p.kind == kind && !p.phase)
      .toList();
  final fitting = ofKind.where((p) => p.fitsStage(stage)).toList();
  return fitting.isEmpty ? ofKind : fitting;
}

/// Phase questions of [kind] for [stage] (may be empty).
List<CompassPrompt> _phasePool(CompassPromptKind kind, LifeStage stage) =>
    compassQuestions
        .where(
          (p) => p.kind == kind && p.phase && p.fits(stage, hasPhase: true),
        )
        .toList();

/// The compassionate note of the week of [date] (deterministic per week).
/// Its text may contain `{weeks}` (see [CompassPrompt.textFor]).
CompassPrompt noteForWeek(DateTime date) =>
    compassNotes[compassWeekIndex(date) % compassNotes.length];

/// A hint for when "Now" is full; any [seed] (e.g. a counter) picks one.
CompassPrompt limitHint(int seed) =>
    compassLimitHints[seed % compassLimitHints.length];

/// [a] divided by positive [b], rounded down (also for negative [a]).
int _floorDiv(int a, int b) => (a - a % b) ~/ b;
