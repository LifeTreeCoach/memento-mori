import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';

/// What the intention flow knows about the user's life right now: the day,
/// birth date, life expectancy, the current phase and the reminder rhythm.
class IntentionFlowContext {
  const IntentionFlowContext({
    required this.today,
    required this.birthDate,
    required this.lifeExpectancyYears,
    required this.phase,
    required this.rhythm,
  });

  /// The context from the stored Compass data and reminder rhythm.
  factory IntentionFlowContext.current({
    required DateTime today,
    required DateTime? birthDate,
    required int lifeExpectancyYears,
  }) {
    return IntentionFlowContext(
      today: today,
      birthDate: birthDate,
      lifeExpectancyYears: lifeExpectancyYears,
      phase: currentSpan(CompassService.data.phases, today),
      rhythm: ReminderService.rhythm(),
    );
  }

  final DateTime today;
  final DateTime? birthDate;
  final int lifeExpectancyYears;

  /// The phase lived [today]; null before the first one.
  final PhaseSpan? phase;
  final ReminderRhythm rhythm;

  /// Age suggested by the "by an age" horizon: the next round decade
  /// (36 -> 40), 50 without a birth date.
  int get suggestedAge {
    final birth = birthDate;
    if (birth == null) return 50;
    final age = LifeCalculator(birthDate: birth, now: today).ageYears;
    return (age ~/ 10 + 1) * 10;
  }
}
