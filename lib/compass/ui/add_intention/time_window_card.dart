import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/time_window.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/intention_flow_context.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/phase_week_dots.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// "Your time window": the planned weeks left in [phase], their share of
/// the lifespan (doTask) or a gentle word (enjoy), what the reminder rhythm
/// will do, and the phase in dots.
class TimeWindowCard extends StatelessWidget {
  const TimeWindowCard({
    super.key,
    required this.flow,
    required this.phase,
    required this.kind,
    required this.dueDate,
  });

  final IntentionFlowContext flow;
  final PhaseSpan phase;
  final IntentionKind? kind;
  final DateTime? dueDate;

  static const double backgroundAlpha = 0.14;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final weeks = phaseWeeks(phase, flow.today);
    final body = _body(l10n, weeks);
    final gold = PhaseColors.of(context).current;
    return Container(
      key: const ValueKey('intention_time_window'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            gold.withValues(alpha: backgroundAlpha), scheme.surface),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.translate('intention_window_label').toUpperCase(),
              style: PhaseStyle.eyebrow(context)),
          const SizedBox(height: 8),
          Text(_headline(l10n, weeks),
              key: const ValueKey('intention_window_headline'),
              style: Theme.of(context).textTheme.titleMedium),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body.join(' '),
                key: const ValueKey('intention_window_body'),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (weeks != null && weeks.total > 0) ...[
            const SizedBox(height: 14),
            PhaseWeekDots(weeks: weeks),
          ],
        ],
      ),
    );
  }

  String _headline(AppLocalizations l10n, PhaseWeeks? weeks) {
    if (weeks == null) return l10n.translate('intention_window_open');
    if (weeks.left <= 0) return l10n.translate('intention_window_ending');
    return l10n.plural('intention_window_weeks', weeks.left);
  }

  List<String> _body(AppLocalizations l10n, PhaseWeeks? weeks) {
    if (kind == IntentionKind.enjoy) return [_enjoyText(l10n)];
    return [
      if (weeks != null && weeks.left > 0) ...[
        if (_share(weeks) case final share?)
          l10n.translate('intention_window_share',
              replacements: {'p': l10n.percentText(share)}),
        l10n.translate('intention_window_nudge'),
      ],
      ?l10n.rhythmSentence(flow.rhythm),
    ];
  }

  double? _share(PhaseWeeks weeks) => flow.birthDate == null
      ? null
      : weeksShareOfLifespan(weeks.left, flow.lifeExpectancyYears);

  String _enjoyText(AppLocalizations l10n) {
    final due = dueDate;
    if (due == null) return l10n.translate('intention_window_enjoy');
    return l10n.translate('intention_window_enjoy_dated',
        replacements: {'date': l10n.dayText(due, today: flow.today)});
  }
}
