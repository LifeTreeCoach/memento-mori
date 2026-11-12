import 'package:intl/intl.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Name of [phase]: the translated preset (follows the app language),
/// otherwise the user's own name.
String phaseDisplayName(LifePhase phase, AppLocalizations l10n) {
  final preset = phase.preset;
  return preset == null ? phase.name : l10n.presetName(preset);
}

/// Phase names joined with " · " for a wrapping legend. The space before the
/// separator is non-breaking, so a wrapped line never starts with "·".
String joinPhaseNames(Iterable<String> names) => names.join('\u00A0· ');

/// Localized texts of life phases.
extension PhaseLabels on AppLocalizations {
  String presetName(PhasePreset preset) =>
      translate('phase_preset_${preset.name}');

  /// "4 y 2 mo" / "4 J 2 M"; only the non-zero parts (months when both 0).
  String compactDuration(int months) {
    final years = months ~/ 12;
    final rest = months % 12;
    return [
      if (years > 0) plural('phase_short_years', years),
      if (rest > 0 || years == 0) plural('phase_short_months', rest),
    ].join(' ');
  }

  /// "seit 4 J 2 M", or "gerade begonnen" for less than a month.
  String sinceText(int months) => months <= 0
      ? translate('phase_just_begun')
      : translate('phase_since', replacements: {'d': compactDuration(months)});

  /// "Seit 2 Jahren und 8 Monaten" in full words for the phase header;
  /// only the non-zero parts, "Gerade begonnen" for less than a month.
  String sinceLongText(int months) {
    if (months <= 0) return translate('phase_just_begun_long');
    final years = months ~/ 12;
    final rest = months % 12;
    final y = years > 0 ? plural('phase_since_long_years', years) : null;
    final m = rest > 0 ? plural('phase_since_long_months', rest) : null;
    final duration = y != null && m != null
        ? translate('phase_since_long_both', replacements: {'y': y, 'm': m})
        : (y ?? m)!;
    return translate('phase_since_long', replacements: {'d': duration});
  }

  /// "5 % deiner Lebensspanne" for a [share] of 0..1 ("<1" below 1 %).
  String lifespanShareText(double share) {
    final percent = (share * 100).round();
    final p = percent < 1 ? '<1' : numberFormat.format(percent);
    return translate('phase_share', replacements: {'p': p});
  }

  /// "Geplant: noch etwa 14 Monate" (weeks under a month); null without
  /// time left.
  String? plannedLeftText({required int? months, required int? weeks}) {
    if (months != null && months > 0) {
      return plural('phase_planned_left', months);
    }
    if (weeks != null && weeks > 0) {
      return plural('phase_planned_weeks_left', weeks);
    }
    return null;
  }

  /// "insgesamt etwa 9 % deiner Lebensspanne" for the whole planned phase.
  String totalShareText(double share) {
    final percent = (share * 100).round();
    final p = percent < 1 ? '<1' : numberFormat.format(percent);
    return translate('duration_total_share', replacements: {'p': p});
  }

  /// "bis etwa Mai 2027".
  String plannedUntilText(DateTime end) => translate('duration_until',
      replacements: {'date': DateFormat.yMMMM(locale.languageCode).format(end)});

  String startErrorText(PhaseStartError error) =>
      translate('phase_error_${error.name}');
}
