import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/since_stepper.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// The phase being chosen in the phase editor: a preset or an own name and
/// how long ago it began. Starts a new phase or edits [editing].
class PhaseDraft {
  PhaseDraft({
    this.editing,
    required DateTime today,
    this.birthDate,
    required this.lifeExpectancyYears,
  })  : today = compassDate(today),
        preset = editing?.preset,
        name = editing?.preset == null ? editing?.name ?? '' : '',
        months = editing == null ? 0 : _monthsSince(editing.start, today);

  final LifePhase? editing;
  final DateTime today;
  final DateTime? birthDate;
  final int lifeExpectancyYears;

  PhasePreset? preset;
  String name;

  /// How long ago the phase began, in months.
  int months;

  /// The stepper was used, so the start is recomputed from [months].
  bool startChanged = false;

  static int _monthsSince(DateTime start, DateTime today) =>
      LifeCalculator(birthDate: start, now: today).monthsLived;

  bool get isNew => editing == null;

  bool get canSave => preset != null || name.trim().isNotEmpty;

  String displayName(AppLocalizations l10n) =>
      preset == null ? name.trim() : l10n.presetName(preset!);

  /// Upper bound of [months]: the age when the birth date is known.
  int get maxMonths => birthDate == null
      ? SinceSteps.maxMonthsWithoutBirthDate
      : _monthsSince(birthDate!, today);

  /// The start day: kept while editing without stepping, else [months] ago.
  DateTime get start => !startChanged && editing != null
      ? editing!.start
      : startFromAgo(today, months ~/ 12, months % 12, birthDate: birthDate);

  void setMonths(int value) {
    months = value;
    startChanged = true;
  }

  /// The lifespan bar; null without a birth date.
  LifespanBarFractions? get fractions => birthDate == null
      ? null
      : LifespanBarFractions.of(
          birthDate: birthDate!,
          lifeExpectancyYears: lifeExpectancyYears,
          start: start,
          today: today,
          plannedEnd: editing?.plannedEnd,
        );

  /// Share of the lifespan so far; null without a birth date.
  double? get share =>
      birthDate == null ? null : shareOfLifespan(months, lifeExpectancyYears);

  /// Why the phase cannot start on [day] (default [start]), or null.
  PhaseStartError? validate({DateTime? day}) => validateStart(
        day ?? start,
        birthDate: birthDate,
        today: today,
        others: CompassService.data.phases,
        ignoreId: editing?.id,
      );

  /// Saves the phase (starting on [day], default [start]).
  Future<void> save({DateTime? day}) async {
    final first = day ?? start;
    final ownName = preset == null ? name.trim() : '';
    final edited = editing;
    if (edited == null) {
      await CompassService.startPhase(
          preset: preset, name: ownName, start: first, today: today);
      return;
    }
    await CompassService.editPhase(LifePhase(
      id: edited.id,
      name: ownName,
      preset: preset,
      start: first,
      plannedEnd: edited.plannedEnd,
      note: edited.note,
    ));
  }
}
