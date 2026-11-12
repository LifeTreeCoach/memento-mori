import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// Shared text styles of the phase visuals.
class PhaseStyle {
  PhaseStyle._();

  /// Contrast the gold accent text keeps against the surface.
  static const double minTextContrast = 3;

  /// Small spaced capitals above a heading ("PHASE").
  static TextStyle? eyebrow(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 1.6,
    );
  }

  /// Quiet secondary text (muted body small).
  static TextStyle? muted(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
  }

  /// Body small in the current phase's gold, darkened until readable.
  static TextStyle? gold(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall?.copyWith(
      color: readableGold(context),
      fontWeight: FontWeight.w600,
    );
  }

  /// [PhaseColors.current] moved towards onSurface until it reaches
  /// [minTextContrast] on the surface.
  static Color readableGold(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = PhaseColors.of(context).current;
    var color = gold;
    for (var t = 0.1;
        contrastRatio(color, scheme.surface) < minTextContrast && t <= 1;
        t += 0.1) {
      color = Color.lerp(gold, scheme.onSurface, t)!;
    }
    return color;
  }
}

/// [text] in spaced capitals ("ODER EIGENER NAME"), with room above.
class PhaseEyebrow extends StatelessWidget {
  const PhaseEyebrow(this.text, {super.key, this.top = 0});

  final String text;

  /// Space above the label.
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 8),
      child: Text(text.toUpperCase(), style: PhaseStyle.eyebrow(context)),
    );
  }
}

/// A [PhaseEyebrow] that shows [long] ("YOUR LIFE PHASE") when it fits on one
/// line in the available width and [short] ("PHASE") otherwise.
class FittingPhaseEyebrow extends StatelessWidget {
  const FittingPhaseEyebrow({
    super.key,
    required this.long,
    required this.short,
    this.top = 0,
  });

  final String long;
  final String short;

  /// Space above the label.
  final double top;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => PhaseEyebrow(
        fitsOneLine(context, long, constraints.maxWidth) ? long : short,
        top: top,
      ),
    );
  }

  /// Whether [text], as an eyebrow, fits on one line within [maxWidth].
  static bool fitsOneLine(BuildContext context, String text, double maxWidth) {
    if (!maxWidth.isFinite) return true;
    final painter = TextPainter(
      text: TextSpan(text: text.toUpperCase(), style: PhaseStyle.eyebrow(context)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }
}
