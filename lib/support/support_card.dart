import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/support/prompt_card_frame.dart';
import 'package:memento_mori_life_in_weeks/support/support_prompt.dart';

/// The occasional, dismissible "support the app" card at the top of the
/// Life tab. Every button closes it; none of them is pre-selected.
class SupportCard extends StatelessWidget {
  const SupportCard({
    super.key,
    required this.usage,
    required this.onSupport,
    required this.onNotNow,
    required this.onAlreadySupported,
  });

  final SupportUsage usage;
  final VoidCallback onSupport;
  final VoidCallback onNotNow;
  final VoidCallback onAlreadySupported;

  static String usageText(AppLocalizations l10n, SupportUsage usage) {
    if (usage.years > 0) return l10n.plural('support_card_years', usage.years);
    return l10n.translate(
      usage.halfYear ? 'support_card_half_year' : 'support_card_month',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PromptCardFrame(
      icon: Icons.favorite_outline,
      text:
          '${usageText(l10n, usage)} '
          '${l10n.translate('support_card_body')}',
      primary: FilledButton(
        key: const ValueKey('support_card_action'),
        onPressed: onSupport,
        child: Text(l10n.translate('support_card_support')),
      ),
      secondary: [
        TextButton(
          onPressed: onNotNow,
          child: Text(l10n.translate('support_card_not_now')),
        ),
        TextButton(
          onPressed: onAlreadySupported,
          child: Text(l10n.translate('support_card_done')),
        ),
      ],
    );
  }
}
