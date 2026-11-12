import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/earlier_phases.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_bilanz.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/time_window.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/phase_week_dots.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_sheet_frame.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_sheet/phase_bilanz_list.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_sheet/phase_sheet_actions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_sheet/phase_sheet_rhythm.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_sheet/phase_stat_tiles.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_permission.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// What the phase sheet asks its opener to do after it closed.
enum PhaseSheetResult { closePhase }

/// Opens [sheet] as a Compass bottom sheet.
Future<PhaseSheetResult?> showPhaseSheet(BuildContext context, PhaseSheet sheet) =>
    showCompassSheet<PhaseSheetResult>(context, (_) => sheet);

/// "Your phase": how long the current phase has lasted, its weeks, what it
/// held (lived / open / let go), its reminder rhythm and the ways on:
/// close it, add earlier phases or change its planned duration. Redraws
/// on every Compass change.
class PhaseSheet extends StatefulWidget {
  const PhaseSheet({
    super.key,
    required this.today,
    required this.birthDate,
    required this.onEarlier,
    required this.onDuration,
    this.permission = const SystemNotificationPermission(),
  });

  final DateTime today;
  final DateTime? birthDate;

  /// Opens the earlier phases editor (above the sheet).
  final VoidCallback onEarlier;

  /// Opens the planned duration editor (above the sheet).
  final VoidCallback onDuration;
  final NotificationPermission permission;

  @override
  State<PhaseSheet> createState() => _PhaseSheetState();
}

class _PhaseSheetState extends State<PhaseSheet> {
  @override
  void initState() {
    super.initState();
    CompassService.revision.addListener(_onChanged);
  }

  @override
  void dispose() {
    CompassService.revision.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final span = currentSpan(CompassService.data.phases, widget.today);
    if (span == null) return const SizedBox.shrink();
    return ScrollThread(
      child: SingleChildScrollView(
        key: const ValueKey('phase_sheet'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _content(context, span),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, PhaseSpan span) {
    final l10n = AppLocalizations.of(context);
    final today = widget.today;
    return [
      PhaseEyebrow(l10n.translate('phase_sheet_eyebrow')),
      Text(phaseDisplayName(span.phase, l10n),
          key: const ValueKey('phase_sheet_name'),
          style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 6),
      Text(_dates(l10n, span), style: PhaseStyle.muted(context)),
      const SizedBox(height: 8),
      Text(l10n.translate('phase_sheet_hint'),
          key: const ValueKey('phase_sheet_hint'),
          style: PhaseStyle.muted(context)),
      const SizedBox(height: 20),
      PhaseStatTiles(span: span, today: today, birthDate: widget.birthDate),
      ..._weeks(l10n, span),
      ..._bilanzAndActions(context, l10n, span),
    ];
  }

  List<Widget> _bilanzAndActions(
      BuildContext context, AppLocalizations l10n, PhaseSpan span) {
    final today = widget.today;
    return [
      const SizedBox(height: 24),
      PhaseBilanzList(
        bilanz: PhaseBilanz.of(CompassService.data, span, today),
        onLetGo: (i) => CompassService.letGoIntention(i.id, today: today),
        onToSomeday: (i) => CompassService.moveToSomeday(i.id),
      ),
      const SizedBox(height: 24),
      PhaseEyebrow(l10n.translate('phase_sheet_remind')),
      PhaseSheetRhythm(permission: widget.permission),
      const SizedBox(height: 24),
      PhaseSheetActions(
        onClose: () => Navigator.of(context).pop(PhaseSheetResult.closePhase),
        onContinue: () => Navigator.of(context).pop(),
        onEarlier: widget.onEarlier,
        onDuration: widget.onDuration,
        hasEarlierPhases:
            earlierSpans(CompassService.data.phases, today).isNotEmpty,
      ),
    ];
  }

  /// "since September 2022 · planned until December 2027".
  String _dates(AppLocalizations l10n, PhaseSpan span) {
    final format = DateFormat.yMMMM(l10n.locale.languageCode);
    final end = span.phase.plannedEnd;
    return [
      l10n.translate('phase_sheet_since',
          replacements: {'date': format.format(span.start)}),
      end == null
          ? l10n.translate('phase_sheet_open_end')
          : l10n.translate('phase_sheet_until',
              replacements: {'date': format.format(end)}),
    ].join(' · ');
  }

  /// "This phase in weeks": lived weeks and, with a planned end, the rest.
  List<Widget> _weeks(AppLocalizations l10n, PhaseSpan span) {
    final weeks = phaseWeeks(span, widget.today) ??
        PhaseWeeks(
            lived: LifeCalculator(birthDate: span.start, now: widget.today)
                .weeksLived,
            left: 0);
    if (weeks.total == 0) return const [];
    return [
      PhaseEyebrow(l10n.translate('phase_sheet_weeks'), top: 24),
      PhaseWeekDots(weeks: weeks),
    ];
  }
}
