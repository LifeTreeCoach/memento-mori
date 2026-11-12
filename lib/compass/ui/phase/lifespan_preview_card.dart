import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/lifespan_bar.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Live preview of the phase being chosen: its name, "seit 4 J 2 M" and
/// the lifespan bar with "5 % deiner Lebensspanne"; without a birth date
/// ([fractions] null) a hint instead of the bar.
class LifespanPreviewCard extends StatelessWidget {
  const LifespanPreviewCard({
    super.key,
    required this.name,
    required this.months,
    required this.fractions,
    required this.share,
    required this.lifeExpectancyYears,
    this.shareText,
    this.detail,
  });

  final String name;

  /// Months the phase has lasted so far.
  final int months;
  final LifespanBarFractions? fractions;

  /// Share (0..1) of the lifespan; null (or a phase just begun) hides it.
  final double? share;
  final int lifeExpectancyYears;

  /// Replaces the text from [share] under the bar (e.g. the share of the
  /// whole planned phase).
  final String? shareText;

  /// An extra line under the bar ("until about May 2027").
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('phase_preview_card'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(context, l10n),
          const SizedBox(height: 14),
          ..._lifespan(context, l10n),
        ],
      ),
    );
  }

  Widget _title(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(name.isEmpty ? '–' : name,
              style: theme.textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 12),
        Text(l10n.sinceText(months), style: PhaseStyle.muted(context)),
      ],
    );
  }

  List<Widget> _lifespan(BuildContext context, AppLocalizations l10n) {
    final bar = fractions;
    if (bar == null) {
      return [
        Text(l10n.translate('phase_no_birth_date'),
            style: PhaseStyle.muted(context)),
        ..._detail(context),
      ];
    }
    final shareText = this.shareText ??
        (share == null || months <= 0 ? null : l10n.lifespanShareText(share!));
    return [
      LifespanBar(fractions: bar, semanticsLabel: shareText),
      const SizedBox(height: 6),
      _scale(context, l10n, shareText),
      ..._detail(context),
    ];
  }

  List<Widget> _detail(BuildContext context) {
    final text = detail;
    if (text == null) return const [];
    return [
      const SizedBox(height: 6),
      Text(text,
          key: const ValueKey('phase_preview_detail'),
          textAlign: TextAlign.center,
          style: PhaseStyle.muted(context)),
    ];
  }

  /// "Geburt · 5 % deiner Lebensspanne · 80 J" under the bar.
  Widget _scale(BuildContext context, AppLocalizations l10n, String? share) {
    final muted = PhaseStyle.muted(context);
    return Row(
      children: [
        Text(l10n.translate('phase_birth'), style: muted),
        // The bar above already announces the share to screen readers.
        Expanded(
          child: ExcludeSemantics(
            child: Text(share ?? '',
                key: const ValueKey('phase_preview_share'),
                textAlign: TextAlign.center,
                style: PhaseStyle.gold(context)),
          ),
        ),
        Text(l10n.plural('phase_short_years', lifeExpectancyYears),
            style: muted),
      ],
    );
  }
}
