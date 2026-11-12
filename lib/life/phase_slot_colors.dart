import 'package:flutter/painting.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// Colour of a phase run, shared by the grid, the legend and the
/// alternative layouts.
extension PhaseSlotColors on PhaseColors {
  /// Earlier phases cycle through [PhaseColors.earlier] by [earlierIndex].
  Color forSlot(PhaseSlotKind kind, int earlierIndex) => switch (kind) {
        PhaseSlotKind.earlier => earlierAt(earlierIndex < 0 ? 0 : earlierIndex),
        PhaseSlotKind.current => current,
        PhaseSlotKind.planned => planned,
      };

  /// Colour of [run].
  Color forRun(PhaseCellRun run) => forSlot(run.kind, run.earlierIndex);
}
