import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';

/// Two tiny cells (lived, remaining) previewing a grid palette.
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({super.key, required this.theme});

  final ColorTheme theme;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell(theme.livedColor),
          const SizedBox(width: 4),
          _cell(theme.remainingColor),
        ],
      ),
    );
  }

  Widget _cell(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: theme.borderColor, width: 1),
      ),
    );
  }
}
