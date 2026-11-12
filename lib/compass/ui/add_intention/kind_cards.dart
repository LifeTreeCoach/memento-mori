import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// "Get something done" / "Enjoy something" as two cards side by side; the
/// chosen one is filled with ink. With [allowNone] tapping it again clears
/// the choice (older intentions have no kind).
class KindCards extends StatelessWidget {
  const KindCards({
    super.key,
    required this.selected,
    required this.onChanged,
    this.allowNone = false,
  });

  final IntentionKind? selected;
  final ValueChanged<IntentionKind?> onChanged;
  final bool allowNone;

  void _tap(IntentionKind kind) =>
      onChanged(allowNone && kind == selected ? null : kind);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final kind in IntentionKind.values) ...[
            if (kind != IntentionKind.values.first) const SizedBox(width: 10),
            Expanded(
              child: _KindCard(
                kind: kind,
                selected: kind == selected,
                onTap: () => _tap(kind),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final IntentionKind kind;
  final bool selected;
  final VoidCallback onTap;

  bool get _isDo => kind == IntentionKind.doTask;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final background = selected ? scheme.onSurface : scheme.surface;
    final foreground = selected ? scheme.surface : scheme.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        key: ValueKey('intention_kind_${kind.name}'),
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: selected ? scheme.onSurface : scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _texts(context, l10n, foreground),
          ),
        ),
      ),
    );
  }

  Widget _texts(BuildContext context, AppLocalizations l10n, Color color) {
    final text = Theme.of(context).textTheme;
    final key = _isDo ? 'intention_kind_do' : 'intention_kind_enjoy';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _isDo ? Icons.check_box_outlined : Icons.favorite_border_rounded,
          color: color,
          size: 22,
        ),
        const SizedBox(height: 10),
        Text(l10n.translate(key),
            style: text.titleSmall?.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(l10n.translate('${key}_sub'),
            style: text.bodySmall
                ?.copyWith(color: color.withValues(alpha: 0.75))),
      ],
    );
  }
}
