import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/support/prompt_card_frame.dart';
import 'package:memento_mori_life_in_weeks/support/support_card.dart';
import 'package:memento_mori_life_in_weeks/support/support_prompt.dart';

/// The store builds' version of [SupportCard]: same schedule and place on
/// the Life tab, but it asks for a rating or a recommendation, never money.
/// The main button rates when [canRate], else it recommends. Every button
/// closes it.
class RecommendCard extends StatelessWidget {
  const RecommendCard({
    super.key,
    required this.usage,
    required this.canRate,
    required this.onRate,
    required this.onRecommend,
    required this.onNotNow,
    required this.onAlreadyDid,
  });

  final SupportUsage usage;
  final bool canRate;
  final VoidCallback onRate;
  final VoidCallback onRecommend;
  final VoidCallback onNotNow;
  final VoidCallback onAlreadyDid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PromptCardFrame(
      icon: Icons.star_outline,
      text:
          '${SupportCard.usageText(l10n, usage)} '
          '${l10n.translate('recommend_card_body')}',
      primary: FilledButton(
        key: const ValueKey('recommend_card_action'),
        onPressed: canRate ? onRate : onRecommend,
        child: Text(
          l10n.translate(
            canRate ? 'recommend_card_rate' : 'recommend_card_share',
          ),
        ),
      ),
      secondary: [
        TextButton(
          onPressed: onNotNow,
          child: Text(l10n.translate('support_card_not_now')),
        ),
        TextButton(
          onPressed: onAlreadyDid,
          child: Text(l10n.translate('support_card_done')),
        ),
      ],
    );
  }
}
