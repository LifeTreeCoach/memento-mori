import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/data/friends_import_export_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_flow.dart';
import 'package:memento_mori_life_in_weeks/settings/data_protection_screen.dart';
import 'package:memento_mori_life_in_weeks/settings/external_link.dart';
import 'package:memento_mori_life_in_weeks/settings/settings_section.dart';

/// Import and export of people, and how the data is protected.
class DataSection extends StatelessWidget {
  const DataSection({super.key, this.openLink = openExternalLink});

  /// Opens the privacy policy from the data protection screen; injectable
  /// for tests.
  final ExternalLinkOpener openLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.translate('settings_section_data'),
      children: [
        ListTile(
          key: const ValueKey('settings-import-birthdays'),
          leading: const Icon(Icons.cake_outlined),
          title: Text(l10n.translate('import_birthdays')),
          subtitle: Text(l10n.translate('import_birthdays_sub')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => startBirthdayImport(context),
        ),
        ListTile(
          leading: const Icon(Icons.import_export),
          title: Text(l10n.translate('people_import_export')),
          subtitle: Text(l10n.translate('settings_import_export_sub')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const FriendsImportExportScreen(),
          )),
        ),
        ListTile(
          key: const ValueKey('settings-data-protection'),
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.translate('data_protection_title')),
          subtitle: Text(l10n.translate('data_protection_tile_sub')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => DataProtectionScreen(openLink: openLink),
          )),
        ),
      ],
    );
  }
}
