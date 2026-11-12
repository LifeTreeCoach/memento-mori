import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/earlier_phases.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';

/// An earlier phase being added or edited: a preset or own name and its
/// start, as an age (with a birth date) or a calendar year (without).
class EarlierPhaseDraft {
  EarlierPhaseDraft({this.editing, required DateTime today, this.birthDate})
      : today = compassDate(today),
        preset = editing?.preset,
        name = editing?.preset == null ? editing?.name ?? '' : '',
        value = _initialValue(editing, birthDate, compassDate(today));

  final LifePhase? editing;
  final DateTime today;
  final DateTime? birthDate;

  PhasePreset? preset;
  String name;

  /// Age in years (with a birth date) or calendar year of the start.
  int value;

  /// The stepper was used, so the start is recomputed from [value].
  bool startChanged = false;

  /// How far back a year can go without a birth date.
  static const int maxYearsBack = 120;

  static int _initialValue(LifePhase? editing, DateTime? birth, DateTime today) {
    if (editing != null) {
      return birth == null ? editing.start.year : ageOn(birth, editing.start);
    }
    return birth == null ? today.year - 10 : 0;
  }

  bool get byAge => birthDate != null;
  int get min => byAge ? 0 : today.year - maxYearsBack;
  int get max => byAge ? ageOn(birthDate!, today) : today.year;
  bool get canSave => preset != null || name.trim().isNotEmpty;

  void setValue(int next) {
    value = next;
    startChanged = true;
  }

  /// Kept while editing without stepping, else from [value].
  DateTime get start => !startChanged && editing != null
      ? editing!.start
      : byAge
          ? startAtAge(birthDate!, value)
          : DateTime(value);

  PhaseStartError? validate() => validateEarlierStart(start,
      birthDate: birthDate,
      today: today,
      phases: CompassService.data.phases,
      ignoreId: editing?.id);

  /// Adds the phase, or saves the edited one (planned end and note kept).
  Future<void> save() async {
    final ownName = preset == null ? name.trim() : '';
    final edited = editing;
    if (edited == null) {
      await CompassService.startPhase(
          preset: preset, name: ownName, start: start, today: today);
      return;
    }
    await CompassService.editPhase(LifePhase(
        id: edited.id,
        name: ownName,
        preset: preset,
        start: start,
        plannedEnd: edited.plannedEnd,
        note: edited.note));
  }
}
