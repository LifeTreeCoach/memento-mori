import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';

/// Closing step 1: per open intention "Take along" (default) or "Let go".
/// Let-go intentions stay visible, nothing is deleted.
class CloseOpenItemsStep extends StatelessWidget {
  const CloseOpenItemsStep({
    super.key,
    required this.eyebrow,
    required this.items,
    required this.takeAlong,
    required this.onChanged,
    required this.onNext,
  });

  final String eyebrow;
  final List<Intention> items;
  final Map<String, bool> takeAlong;
  final void Function(String id, bool take) onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StepLayout(
      topPadding: 8,
      action: FilledButton(
        key: const ValueKey('phase_close_next'),
        onPressed: onNext,
        child: Text(l10n.translate('phase_close_next')),
      ),
      children: [
        PhaseEyebrow(eyebrow),
        Text(l10n.translate('phase_close_items_title'),
            style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(l10n.translate('phase_close_items_intro'),
            style: PhaseStyle.muted(context)),
        const SizedBox(height: 16),
        for (final item in items) _item(context, l10n, item),
      ],
    );
  }

  Widget _item(BuildContext context, AppLocalizations l10n, Intention item) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('phase_close_item_${item.id}'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _choice(l10n, item.id),
        ],
      ),
    );
  }

  Widget _choice(AppLocalizations l10n, String id) {
    ButtonSegment<bool> segment(bool take, String key, String text) =>
        ButtonSegment(
          value: take,
          label: Text(l10n.translate(text),
              key: ValueKey('${key}_$id'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        );
    return SegmentedButton<bool>(
      segments: [
        segment(true, 'phase_close_take', 'phase_close_take'),
        segment(false, 'phase_close_let_go', 'phase_bilanz_let_go'),
      ],
      selected: {takeAlong[id] ?? true},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(id, selection.single),
    );
  }
}
