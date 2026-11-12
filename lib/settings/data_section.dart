import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/data/friends_import_export_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_flow.dart';
import 'package:memento_mori_life_in_weeks/settings/settings_section.dart';

/// Import and export of people.
class DataSection extends StatelessWidget {
  const DataSection({super.key});

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
      ],
    );
  }
}
