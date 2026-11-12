import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/settings_section.dart';
import 'package:memento_mori_life_in_weeks/settings/sponsor_link.dart';
import 'package:memento_mori_life_in_weeks/settings/support_reminder_switch.dart';

/// Support: the Buy Me a Coffee link (honest copy) and the opt-out of the
/// occasional support card on the Life tab. Builds outside the stores only
/// (`SupportChannel.link`); store builds show `RecommendSection`.
class SupportSection extends StatelessWidget {
  const SupportSection({super.key, this.openLink = openSponsorLink});

  /// Opens the sponsor page; injectable for tests.
  final SponsorLinkOpener openLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.translate('settings_section_support'),
      children: [
        ListTile(
          key: const ValueKey('support_coffee_tile'),
          leading: const Icon(Icons.favorite_outline),
          title: Text(l10n.translate('support_coffee')),
          subtitle: Text(l10n.translate('support_settings_body')),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () => openLink(context),
        ),
        const SupportReminderSwitch(),
      ],
    );
  }
}
