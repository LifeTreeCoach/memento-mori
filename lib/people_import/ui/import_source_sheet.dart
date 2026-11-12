import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../people/sheet_title.dart';
import '../../widgets/scroll_thread.dart';
import 'import_sheet_parts.dart';

/// Where the user wants to import birthdays from.
enum ImportSourceChoice {
  /// All device contacts (needs the contacts permission).
  allContacts,

  /// System contact picker (Android 17+, iOS; no permission).
  pickContacts,

  /// A .vcf file.
  vcard,
}

/// Asks where to import from. With the system contact picker
/// ([pickerSupported]: Android 17+ and iOS) the contacts option splits into
/// "choose contacts" (recommended) and "search all contacts".
Future<ImportSourceChoice?> showImportSourceSheet(
  BuildContext context, {
  required bool pickerSupported,
}) {
  return showModalBottomSheet<ImportSourceChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ImportSourceSheet(pickerSupported: pickerSupported),
  );
}

/// Content of [showImportSourceSheet].
class ImportSourceSheet extends StatelessWidget {
  const ImportSourceSheet({super.key, required this.pickerSupported});

  final bool pickerSupported;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: ScrollThread(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(l10n.translate('import_source_title')),
              ..._contactOptions(context, l10n),
              _option(
                context,
                ImportSourceChoice.vcard,
                Icons.description_outlined,
                l10n.translate('import_source_vcard'),
                l10n.translate('import_source_vcard_sub'),
              ),
              const SizedBox(height: 8),
              PrivacyLine(text: l10n.translate('import_privacy')),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contactOptions(BuildContext context, AppLocalizations l10n) {
    if (!pickerSupported) {
      return [
        _option(
          context,
          ImportSourceChoice.allContacts,
          Icons.contacts_outlined,
          l10n.translate('import_source_contacts'),
          l10n.translate(_contactsSubKey),
          recommended: true,
        ),
      ];
    }
    return [
      _option(
        context,
        ImportSourceChoice.pickContacts,
        Icons.how_to_reg_outlined,
        l10n.translate('import_source_pick'),
        '${l10n.translate(_pickSubKey)}\n'
        '${l10n.translate(_contactsSubKey)}',
        recommended: true,
      ),
      _option(
        context,
        ImportSourceChoice.allContacts,
        Icons.contacts_outlined,
        l10n.translate('import_source_all'),
        l10n.translate('import_source_all_sub'),
      ),
    ];
  }

  /// iOS's picker has no 100-contact limit per round.
  static String get _pickSubKey => defaultTargetPlatform == TargetPlatform.iOS
      ? 'import_source_pick_sub_ios'
      : 'import_source_pick_sub';

  /// iOS has no Google Calendar birthdays; it mentions Apple's Birthdays
  /// calendar instead.
  static String get _contactsSubKey =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? 'import_source_contacts_sub_ios'
      : 'import_source_contacts_sub';

  Widget _option(
    BuildContext context,
    ImportSourceChoice choice,
    IconData icon,
    String title,
    String subtitle, {
    bool recommended = false,
  }) {
    return ListTile(
      key: ValueKey('import-source-${choice.name}'),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(subtitle), if (recommended) const RecommendedBadge()],
      ),
      isThreeLine: true,
      onTap: () => Navigator.of(context).pop(choice),
    );
  }
}
