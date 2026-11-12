import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_ribbon.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_overdue_prompt.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Top of the Compass: the current phase, how long it has lasted, its share
/// of the lifespan and a whole-life ribbon of all phases (percentages and
/// ribbon only with a birth date).
class PhaseHeader extends StatelessWidget {
  const PhaseHeader({
    super.key,
    required this.spans,
    required this.today,
    required this.birthDate,
    required this.lifeExpectancyYears,
    required this.onEdit,
    required this.onExtend,
    required this.onClose,
    this.onOpen,
  }) : assert(spans.length > 0);

  /// Phases from [resolvePhases]; the last one is current.
  final List<PhaseSpan> spans;
  final DateTime today;
  final DateTime? birthDate;
  final int lifeExpectancyYears;
  final VoidCallback onEdit;
  final VoidCallback onExtend;
  final VoidCallback onClose;

  /// Opens the phase sheet (tap on the name, subtitle or ribbon).
  final VoidCallback? onOpen;

  PhaseSpan get _current => spans.last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('compass_phase_header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const ValueKey('compass_phase_open_sheet'),
          onTap: onOpen,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FittingPhaseEyebrow(
                long: l10n.translate('phase_header_eyebrow'),
                short: l10n.translate('phase_eyebrow'),
              ),
              _title(context, l10n),
              const SizedBox(height: 6),
              Text(_subtitle(l10n),
                  key: const ValueKey('compass_phase_subtitle'),
                  style: PhaseStyle.muted(context)),
              const SizedBox(height: 14),
              ..._lifespan(context, l10n),
            ],
          ),
        ),
        if (isOverdue(_current, today))
          PhaseOverduePrompt(onExtend: onExtend, onClose: onClose),
      ],
    );
  }

  Widget _title(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            phaseDisplayName(_current.phase, l10n),
            key: const ValueKey('compass_phase_name'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        const SizedBox(width: 12),
        IconButton.outlined(
          key: const ValueKey('compass_phase_edit'),
          tooltip: l10n.translate('phase_edit'),
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
      ],
    );
  }

  /// "Seit 4 Jahren und 2 Monaten · 5 % deiner Lebensspanne".
  String _subtitle(AppLocalizations l10n) {
    final months = monthsIn(_current, today);
    final share = birthDate == null
        ? null
        : shareOfLifespan(months, lifeExpectancyYears);
    return [
      l10n.sinceLongText(months),
      if (share != null && months > 0) l10n.lifespanShareText(share),
    ].join(' · ');
  }

  List<Widget> _lifespan(BuildContext context, AppLocalizations l10n) {
    final birth = birthDate;
    final planned = l10n.plannedLeftText(
      months: plannedMonthsLeft(_current, today),
      weeks: plannedWeeksLeft(_current, today),
    );
    if (birth == null) {
      return [
        Text(l10n.translate('phase_no_birth_date'),
            key: const ValueKey('compass_phase_no_birth_date'),
            style: PhaseStyle.muted(context)),
        if (planned != null) _legend(context, l10n, planned),
      ];
    }
    return [
      PhaseRibbon(segments: ribbonSegments(spans,
          birthDate: birth, lifeExpectancyYears: lifeExpectancyYears,
          today: today)),
      if (spans.length > 1 || planned != null) _legend(context, l10n, planned),
    ];
  }

  /// Earlier phase names (muted) and "Geplant: noch etwa 14 Monate" (gold).
  Widget _legend(BuildContext context, AppLocalizations l10n, String? planned) {
    final earlier = joinPhaseNames([
      for (final span in spans.take(spans.length - 1))
        phaseDisplayName(span.phase, l10n),
    ]);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      // Side by side when both fit, else the plan moves to its own line, so
      // the names keep the full width.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 2,
        children: [
          if (earlier.isNotEmpty)
            Text(earlier, style: PhaseStyle.muted(context)),
          if (planned != null)
            Text(planned, key: const ValueKey('compass_phase_planned'),
                style: PhaseStyle.gold(context)),
        ],
      ),
    );
  }
}
