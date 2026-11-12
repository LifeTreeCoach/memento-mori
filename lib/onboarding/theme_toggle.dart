import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

/// A quiet light/dark switch for the onboarding top bar: a moon while the
/// app is light, a sun while it is dark. Reports the opposite of the
/// brightness currently shown.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.onChanged});

  final ValueChanged<AppBrightness> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final label = AppLocalizations.of(context)
        .translate(isDark ? 'onboarding_theme_light' : 'onboarding_theme_dark');
    return IconButton(
      tooltip: label,
      visualDensity: VisualDensity.compact,
      color: theme.colorScheme.onSurfaceVariant,
      iconSize: 20,
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () {
        Haptics.selection();
        onChanged(isDark ? AppBrightness.light : AppBrightness.dark);
      },
    );
  }
}
