import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/encounter_dots.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/shared_time_painter.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/meeting_frequency.dart';
import 'package:memento_mori_life_in_weeks/people/shared_time.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// The "Together" card on the friend detail screen: the time you may still
/// share with [friend] (after Tim Urban's "The Tail End"), how often you
/// meet, the encounters left and a way to plan time together.
class TogetherView extends StatelessWidget {
  const TogetherView({
    super.key,
    required this.friend,
    required this.time,
    required this.onFrequencyChanged,
    required this.onPlan,
  });

  final Friend friend;
  final SharedTime time;

  /// A chip was picked (null: the selected chip was tapped again).
  final ValueChanged<MeetingFrequency?> onFrequencyChanged;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (time.isBeyondExpectancy)
              Text(l10n.translate('together_gift'),
                  style: theme.textTheme.titleLarge)
            else ..._sharedTime(context, l10n),
            const SizedBox(height: 16),
            Text(
              l10n.translate(_countsKey),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onPlan,
              icon: const Icon(Icons.event_available_outlined),
              label: Text(l10n.translate('together_plan')),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sharedTime(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return [
      Text(_headline(l10n), style: theme.textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(_count(l10n, 'together_alongside', time.livedAlongsideYears.floor()),
          style: muted),
      const SizedBox(height: 16),
      _chart(context, l10n),
      const SizedBox(height: 8),
      const _Legend(),
      const SizedBox(height: 20),
      Text(l10n.translate('together_frequency_question'),
          style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      _frequencyChips(l10n),
      ..._encounters(context, l10n),
      const SizedBox(height: 12),
      Text(_count(l10n, 'together_birthdays', time.birthdaysTogether),
          style: theme.textTheme.bodyLarge),
    ];
  }

  /// "Each of these encounters counts." needs an encounter count above
  /// it; otherwise the standalone "Every encounter counts.".
  String get _countsKey {
    final encounters = time.isBeyondExpectancy
        ? null
        : time.meetingsLeft(friend.meetingFrequency);
    return encounters != null && encounters > 0
        ? 'together_counts'
        : 'together_counts_any';
  }

  String _headline(AppLocalizations l10n) {
    final years = time.remainingYears.round();
    if (years >= 1) return _count(l10n, 'together_headline', years);
    final weeks = time.remainingWeeks < 1 ? 1 : time.remainingWeeks;
    return _count(l10n, 'together_headline_weeks', weeks);
  }

  /// [baseKey] pluralized for [n], with [n] grouped ("4,160").
  static String _count(AppLocalizations l10n, String baseKey, int n) =>
      l10n.plural(baseKey, n,
          replacements: {'n': l10n.numberFormat.format(n)});

  Widget _chart(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: l10n.translate('together_chart_label'),
      child: SizedBox(
        width: double.infinity,
        height: SharedTimePainter.preferredHeight,
        child: CustomPaint(
          painter: SharedTimePainter(
            time: time,
            youLabel: l10n.translate('together_you'),
            themLabel: friend.name,
            todayLabel: l10n.translate('together_today'),
            colors: SharedTimeColors.resolve(LifePalette.of(context), scheme),
            outline: scheme.outlineVariant,
            labelColor: scheme.onSurfaceVariant,
            todayColor: scheme.onSurface,
            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _frequencyChips(AppLocalizations l10n) {
    final selected = friend.meetingFrequency;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final frequency in MeetingFrequency.values)
          ChoiceChip(
            label: Text(l10n.translate('together_freq_${frequency.name}')),
            selected: frequency == selected,
            onSelected: (_) =>
                onFrequencyChanged(frequency == selected ? null : frequency),
          ),
      ],
    );
  }

  List<Widget> _encounters(BuildContext context, AppLocalizations l10n) {
    final encounters = time.meetingsLeft(friend.meetingFrequency);
    if (encounters == null) return const [];
    final theme = Theme.of(context);
    final scale = encountersPerDot(encounters);
    return [
      const SizedBox(height: 16),
      Text(_count(l10n, 'together_encounters', encounters),
          style: theme.textTheme.titleMedium),
      const SizedBox(height: 10),
      EncounterDots(
          encounters: encounters, color: LifePalette.of(context).accent),
      if (scale > 1) ...[
        const SizedBox(height: 6),
        Text(
          l10n.translate('together_dot_scale',
              replacements: {'n': l10n.numberFormat.format(scale)}),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    ];
  }
}

/// Swatches explaining the chart's colours.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SharedTimeColors.resolve(
        LifePalette.of(context), Theme.of(context).colorScheme);
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _swatch(context, colors.together, l10n.translate('together_legend_lived')),
        _swatch(context, colors.ahead, l10n.translate('together_legend_ahead')),
        _swatch(context, colors.own, l10n.translate('together_legend_own')),
      ],
    );
  }

  Widget _swatch(BuildContext context, Color color, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}
