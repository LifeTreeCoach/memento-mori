import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter/painting.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/life/phase_slot_colors.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// A phase run as a share (0..1) of the lifespan, as from [runFractions].
typedef PhaseFraction = ({
  double from,
  double to,
  PhaseSlotKind kind,
  int earlierIndex,
});

/// A coloured stretch of the lifespan, [from] to [to] (0..1).
typedef PhaseBand = ({double from, double to, Color color});

/// Life phase colours for the layouts that are not a grid: which colour a
/// share of the lifespan, an item or a band takes.
@immutable
class PhaseLayoutColors {
  const PhaseLayoutColors({required this.fractions, required this.colors});

  /// Phase runs as shares of the lifespan, oldest first.
  final List<PhaseFraction> fractions;
  final PhaseColors colors;

  /// Colour of the phase at share [t] of the lifespan (from inclusive, to
  /// exclusive), or null outside every phase.
  Color? colorForFraction(double t) {
    for (final f in fractions) {
      if (t >= f.from && t < f.to) {
        return colors.forSlot(f.kind, f.earlierIndex);
      }
    }
    return null;
  }

  /// Colour of item [index] of [total] equal items (index / total, as the
  /// grid cells the fractions were made from), or null.
  Color? colorForItem(int index, int total) =>
      total > 0 ? colorForFraction(index / total) : null;

  /// Bands to stack on a fill reaching [progress]: lived phases cut at
  /// [progress], the planned rest (which follows the current phase) from
  /// [progress] on, so no gap shows at the surface.
  List<PhaseBand> bands(double progress) {
    final bands = <PhaseBand>[];
    for (final f in fractions) {
      final planned = f.kind == PhaseSlotKind.planned;
      final from = planned ? progress : f.from;
      final to = planned ? f.to : (f.to < progress ? f.to : progress);
      if (to > from) {
        bands.add((
          from: from,
          to: to,
          color: colors.forSlot(f.kind, f.earlierIndex),
        ));
      }
    }
    return bands;
  }

  @override
  bool operator ==(Object other) =>
      other is PhaseLayoutColors &&
      other.colors == colors &&
      listEquals(other.fractions, fractions);

  @override
  int get hashCode => Object.hash(colors, Object.hashAll(fractions));
}
