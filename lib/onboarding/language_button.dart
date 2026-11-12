import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/choice_tile.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Opens the language sheet, so it stays one button wide however many
/// languages are supported.
///
/// Regular: "English ▾". [compact]: a quiet "文A DE ▾" chip for the
/// onboarding top bar, muted so it never reads as a primary action.
class LanguageButton extends StatelessWidget {
  const LanguageButton({
    super.key,
    required this.language,
    required this.onChanged,
    this.compact = false,
  });

  final String language;
  final ValueChanged<String> onChanged;
  final bool compact;

  String get _name => AppLocalizations.languageNames[language] ?? language;

  Future<void> _pick(BuildContext context) async {
    final picked = await showChoiceSheet<String>(
      context,
      title: AppLocalizations.of(context).translate('language'),
      options: [
        for (final code in AppLocalizations.supportedLanguages)
          SettingsOption(code, AppLocalizations.languageNames[code] ?? code),
      ],
      selected: language,
    );
    if (picked == null || picked == language) return;
    Haptics.selection();
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildRegular(context);
  }

  Widget _buildRegular(BuildContext context) {
    return TextButton.icon(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => _pick(context),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.arrow_drop_down),
      label: Text(_name),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final label = AppLocalizations.of(context).translate(
      'onboarding_language_semantics',
      replacements: {'language': _name},
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: () => _pick(context),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: muted,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(48, 40),
        ),
        onPressed: () => _pick(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, size: 16, color: muted),
            const SizedBox(width: 4),
            Text(
              language.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
            Icon(Icons.arrow_drop_down, size: 16, color: muted),
          ],
        ),
      ),
    );
  }
}
