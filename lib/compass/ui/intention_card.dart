import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_meta.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_item_menu.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';

/// One "Now" intention as a checkbox row: a rounded checkbox (done), the
/// title in serif type, the note and a meta line with a small dot (ink for
/// getting done, gold for enjoying); tap to edit, a menu for the rest.
class IntentionCard extends StatelessWidget {
  const IntentionCard({
    super.key,
    required this.intention,
    required this.onEdit,
    required this.onDone,
    required this.onAction,
    this.current,
    required this.today,
  });

  final Intention intention;
  final VoidCallback onEdit;
  final VoidCallback onDone;
  final ValueChanged<CompassMenuAction> onAction;

  /// The phase lived [today] (for "~14 months left in this phase").
  final PhaseSpan? current;
  final DateTime today;

  static const List<CompassMenuAction> _menu = [
    CompassMenuAction.edit,
    CompassMenuAction.moveToSomeday,
    CompassMenuAction.letGo,
    CompassMenuAction.delete,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundCheckbox(
                  tooltip: l10n.translate('compass_done'), onPressed: onDone),
              Expanded(child: _texts(context, l10n)),
              CompassItemMenu(actions: _menu, onSelected: onAction),
            ],
          ),
        ),
      ),
    );
  }

  Widget _texts(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final note = intention.note;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(intention.title,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: AppTheme.serifFamily,
                  fontWeight: FontWeight.w500)),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          _meta(context, l10n),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, AppLocalizations l10n) {
    final meta = intentionMetaOf(intention, current: current, today: today);
    final kindText = l10n.kindMetaText(meta, today: today);
    final parts = kindText == null
        ? l10n.intentionMeta(intention)
        : [kindText, if (intention.area case final area?) l10n.areaLabel(area)];
    if (parts.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meta.kind case final kind?) _dot(context, kind),
          Expanded(
            child: Text(parts.join(' · '),
                key: ValueKey('compass_intention_meta_${intention.id}'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _dot(BuildContext context, IntentionKind kind) {
    final color = kind == IntentionKind.enjoy
        ? PhaseStyle.readableGold(context)
        : Theme.of(context).colorScheme.onSurface;
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsetsDirectional.only(top: 5, end: 6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// An empty rounded square that marks the intention done.
class _RoundCheckbox extends StatelessWidget {
  const _RoundCheckbox({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: scheme.outline, width: 1.6),
        ),
      ),
    );
  }
}
