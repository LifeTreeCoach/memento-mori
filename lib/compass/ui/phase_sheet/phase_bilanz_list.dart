import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_bilanz.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// "Review · 2 of 3 intentions lived": lived intentions struck through,
/// let-go ones muted, and a card per open one asking what should happen
/// to it (let go, or move to "Someday").
class PhaseBilanzList extends StatelessWidget {
  const PhaseBilanzList({
    super.key,
    required this.bilanz,
    required this.onLetGo,
    required this.onToSomeday,
  });

  final PhaseBilanz bilanz;
  final ValueChanged<Intention> onLetGo;
  final ValueChanged<Intention> onToSomeday;

  int get _total =>
      bilanz.lived.length + bilanz.open.length + bilanz.letGo.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('phase_bilanz'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PhaseEyebrow(l10n.translate('phase_bilanz_title')),
        Text(_summary(l10n),
            key: const ValueKey('phase_bilanz_summary'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final i in bilanz.lived) _lived(context, i),
        for (final i in bilanz.letGo) _letGo(context, l10n, i),
        for (final i in bilanz.open) _open(context, l10n, i),
      ],
    );
  }

  String _summary(AppLocalizations l10n) => _total == 0
      ? l10n.translate('phase_bilanz_empty')
      : l10n.plural('phase_bilanz_lived', _total, replacements: {
          'n': l10n.numberFormat.format(bilanz.lived.length),
          'total': l10n.numberFormat.format(_total),
        });

  Widget _row(BuildContext context, IconData icon, Color color, Widget text,
      {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(child: text),
      ]),
    );
  }

  Widget _lived(BuildContext context, Intention intention) {
    final theme = Theme.of(context);
    return _row(
      context,
      Icons.check_circle_rounded,
      PhaseStyle.readableGold(context),
      Text(intention.title,
          style: theme.textTheme.bodyLarge
              ?.copyWith(decoration: TextDecoration.lineThrough)),
      key: ValueKey('phase_bilanz_lived_${intention.id}'),
    );
  }

  Widget _letGo(BuildContext context, AppLocalizations l10n, Intention i) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return _row(
      context,
      Icons.air_rounded,
      muted,
      Text.rich(
        TextSpan(text: i.title, children: [
          TextSpan(text: ' · ${l10n.translate('phase_bilanz_let_go_label')}'),
        ]),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: muted),
      ),
      key: ValueKey('phase_bilanz_let_go_${i.id}'),
    );
  }

  Widget _open(BuildContext context, AppLocalizations l10n, Intention i) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('phase_bilanz_open_${i.id}'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(i.title, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(l10n.translate('phase_bilanz_open_question'),
              style: PhaseStyle.muted(context)),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: ValueKey('phase_bilanz_someday_${i.id}'),
                onPressed: () => onToSomeday(i),
                child: Text(l10n.translate('compass_move_someday')),
              ),
              TextButton(
                key: ValueKey('phase_bilanz_let_go_button_${i.id}'),
                onPressed: () => onLetGo(i),
                child: Text(l10n.translate('phase_bilanz_let_go')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
