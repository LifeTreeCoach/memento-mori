import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/settings_section.dart';
import 'package:memento_mori_life_in_weeks/settings/support_reminder_switch.dart';
import 'package:memento_mori_life_in_weeks/support/support_scope.dart';

/// "Like Memento Mori?": the store builds' ([SupportScope] with
/// `SupportChannel.rate`) replacement of the Support section. Rate (only
/// where a store listing exists), recommend, and the same reminder switch;
/// no money or donation wording.
class RecommendSection extends StatelessWidget {
  const RecommendSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final setup = SupportScope.of(context);
    return SettingsSection(
      title: l10n.translate('settings_section_recommend'),
      children: [
        if (setup.listing.canRate)
          ListTile(
            key: const ValueKey('recommend_rate_tile'),
            leading: const Icon(Icons.star_outline),
            title: Text(l10n.translate('recommend_rate')),
            subtitle: Text(l10n.translate('recommend_rate_sub')),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => setup.actions.rate(context, setup.listing),
          ),
        ListTile(
          key: const ValueKey('recommend_share_tile'),
          leading: const Icon(Icons.share_outlined),
          title: Text(l10n.translate('recommend_share')),
          subtitle: Text(l10n.translate('recommend_share_sub')),
          onTap: () => setup.actions.recommend(context, setup.listing),
        ),
        const SupportReminderSwitch(),
      ],
    );
  }
}
