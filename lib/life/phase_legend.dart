import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/life/phase_slot_colors.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// One item of the phase legend: a swatch in the colour of [kind] (and
/// [earlierIndex]) and its [label].
@immutable
class PhaseLegendEntry {
  const PhaseLegendEntry({
    required this.label,
    required this.kind,
    this.earlierIndex = -1,
    this.inGrid = true,
    this.phaseId,
  });

  /// "Kindheit 0–6", "Aufbauphase 32–heute" or "geplant".
  final String label;
  final PhaseSlotKind kind;
  final int earlierIndex;

  /// False for a phase too short to get a cell in the current mode.
  final bool inGrid;

  /// The phase; null for the "planned" entry.
  final String? phaseId;

  /// The current phase (not its planned rest).
  bool get isCurrent => kind == PhaseSlotKind.current;

  @override
  bool operator ==(Object other) =>
      other is PhaseLegendEntry &&
      other.label == label &&
      other.kind == kind &&
      other.earlierIndex == earlierIndex &&
      other.inGrid == inGrid &&
      other.phaseId == phaseId;

  @override
  int get hashCode => Object.hash(label, kind, earlierIndex, inGrid, phaseId);

  @override
  String toString() => 'PhaseLegendEntry($label, ${kind.name}, $inGrid)';
}

/// Legend entries for [spans] (oldest first) and their grid [runs]: every
/// phase with its age range in whole years since [birthDate] (the current
/// one up to "now"), followed by "planned" when a planned run exists. The
/// time before the first phase is not listed. Phases without a run in the
/// current mode are kept, marked with [PhaseLegendEntry.inGrid] false.
List<PhaseLegendEntry> phaseLegendEntries({
  required List<PhaseSpan> spans,
  required List<PhaseCellRun> runs,
  required DateTime birthDate,
  required AppLocalizations l10n,
}) {
  final entries = <PhaseLegendEntry>[
    for (final span in spans) _entryFor(span, runs, birthDate, l10n),
  ];
  if (runs.any((r) => r.kind == PhaseSlotKind.planned)) {
    entries.add(PhaseLegendEntry(
      label: l10n.translate('phase_legend_planned'),
      kind: PhaseSlotKind.planned,
    ));
  }
  return entries;
}

PhaseLegendEntry _entryFor(
  PhaseSpan span,
  List<PhaseCellRun> runs,
  DateTime birthDate,
  AppLocalizations l10n,
) {
  final run = _mainRunOf(span, runs);
  final kind = span.isCurrent ? PhaseSlotKind.current : PhaseSlotKind.earlier;
  return PhaseLegendEntry(
    label: _rangeLabel(span, birthDate, l10n),
    kind: kind,
    earlierIndex: run?.earlierIndex ?? -1,
    inGrid: run != null,
    phaseId: span.phase.id,
  );
}

/// The run of [span] that is not its planned rest, or null.
PhaseCellRun? _mainRunOf(PhaseSpan span, List<PhaseCellRun> runs) {
  for (final run in runs) {
    if (run.phaseId == span.phase.id && run.kind != PhaseSlotKind.planned) {
      return run;
    }
  }
  return null;
}

String _rangeLabel(PhaseSpan span, DateTime birthDate, AppLocalizations l10n) {
  final name = phaseDisplayName(span.phase, l10n);
  final from = '${_ageOn(span.start, birthDate)}';
  final end = span.end;
  if (end == null) {
    return l10n.translate('phase_legend_now',
        replacements: {'name': name, 'from': from});
  }
  return l10n.translate('phase_legend_range',
      replacements: {'name': name, 'from': from, 'to': '${_ageOn(end, birthDate)}'});
}

/// Completed years from [birthDate] to [date] (0 before birth).
int _ageOn(DateTime date, DateTime birthDate) =>
    LifeCalculator(birthDate: birthDate, now: date).ageYears;

/// The legend under the mode selector: small square swatches with the
/// phases' names and ages; the current phase bold in gold. The planned
/// swatch looks like a planned grid cell: the pale planned tint.
class PhaseLegend extends StatelessWidget {
  const PhaseLegend({super.key, required this.entries});

  final List<PhaseLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = PhaseColors.of(context);
    return Wrap(
      key: const ValueKey('phase_legend'),
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final entry in entries)
          _LegendItem(entry: entry, swatch: swatchOf(entry, colors)),
      ],
    );
  }

  /// The swatch of [entry]: filled in its phase colour (a phase without a
  /// run gets the first earlier tone, only outlined), the planned one in
  /// the planned grid tint.
  static PhaseSwatch swatchOf(PhaseLegendEntry entry, PhaseColors colors) {
    if (entry.kind == PhaseSlotKind.planned) {
      return PhaseSwatch(fill: colors.plannedTint);
    }
    final color = colors.forSlot(entry.kind, entry.earlierIndex);
    return entry.inGrid
        ? PhaseSwatch(fill: color)
        : PhaseSwatch(border: color, borderWidth: 1.5);
  }
}

/// Fill and border of a legend swatch (either may be absent).
@immutable
class PhaseSwatch {
  const PhaseSwatch({this.fill, this.border, this.borderWidth = 1});

  final Color? fill;
  final Color? border;
  final double borderWidth;

  @override
  bool operator ==(Object other) =>
      other is PhaseSwatch &&
      other.fill == fill &&
      other.border == border &&
      other.borderWidth == borderWidth;

  @override
  int get hashCode => Object.hash(fill, border, borderWidth);

  @override
  String toString() => 'PhaseSwatch(fill: $fill, border: $border)';
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.entry, required this.swatch});

  static const double _swatchSize = 10;

  final PhaseLegendEntry entry;
  final PhaseSwatch swatch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _swatch(context),
        const SizedBox(width: 6),
        Flexible(child: Text(entry.label, style: _labelStyle(context))),
      ],
    );
  }

  Widget _swatch(BuildContext context) {
    final border = swatch.border;
    return Container(
      width: _swatchSize,
      height: _swatchSize,
      decoration: BoxDecoration(
        color: swatch.fill,
        border: border == null
            ? null
            : Border.all(color: border, width: swatch.borderWidth),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  TextStyle? _labelStyle(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (entry.isCurrent) {
      return base?.copyWith(
        color: PhaseStyle.readableGold(context),
        fontWeight: FontWeight.w700,
      );
    }
    return entry.inGrid ? base : base?.copyWith(fontStyle: FontStyle.italic);
  }
}
