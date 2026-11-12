import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/planned_duration.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// The steps of closing a phase, in order.
enum PhaseCloseStep { openItems, note, next, duration }

/// Everything chosen while closing [closing]: what happens to its open
/// intentions, "what was good", the next phase and its planned duration.
/// Kept across steps (also when going back) and saved in one go.
class PhaseCloseDraft {
  PhaseCloseDraft({
    required this.closing,
    required this.openItems,
    required DateTime today,
  })  : today = compassDate(today),
        takeAlong = {for (final i in openItems) i.id: true};

  final LifePhase closing;

  /// Open intentions of [closing].
  final List<Intention> openItems;
  final DateTime today;

  /// Per open intention: true = take along (default), false = let go.
  final Map<String, bool> takeAlong;

  String note = '';
  PhasePreset? preset;
  String name = '';
  PlannedDuration duration = const PlannedDuration.months(12);

  /// Id of the next phase, fixed so every step shows the same phase.
  late final String nextId = CompassService.newId();

  /// The steps to show; without open intentions the first is skipped.
  List<PhaseCloseStep> get steps => [
        for (final step in PhaseCloseStep.values)
          if (step != PhaseCloseStep.openItems || openItems.isNotEmpty) step,
      ];

  bool get hasNextName => preset != null || name.trim().isNotEmpty;

  String nextName(AppLocalizations l10n) =>
      preset == null ? name.trim() : l10n.presetName(preset!);

  /// The phase that begins today.
  LifePhase get next => LifePhase(
        id: nextId,
        name: preset == null ? name.trim() : '',
        preset: preset,
        start: today,
        plannedEnd: duration.endFrom(today),
      );

  Set<String> get carryOver => {
        for (final e in takeAlong.entries)
          if (e.value) e.key,
      };

  Set<String> get letGo => {
        for (final e in takeAlong.entries)
          if (!e.value) e.key,
      };

  /// Why the next phase cannot begin today (e.g. [closing] began today).
  PhaseStartError? validateNext() => validateStart(today,
      today: today, others: CompassService.data.phases);

  /// Closes [closing] and starts [next] in one save.
  Future<void> save() => CompassService.closePhase(
        closingId: closing.id,
        note: note,
        next: next,
        carryOver: carryOver,
        letGo: letGo,
        today: today,
      );
}
