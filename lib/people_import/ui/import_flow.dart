import 'package:flutter/material.dart';

import '../../friends_service.dart';
import '../../localization.dart';
import '../contacts_source.dart';
import '../import_applier.dart';
import '../vcard_source.dart';
import 'contacts_explainer_sheet.dart';
import 'contacts_import_screen.dart';
import 'import_result_report.dart';
import 'import_review_model.dart';
import 'import_review_screen.dart';
import 'import_services.dart';
import 'import_source_sheet.dart';

/// The birthday import from an entry point (People tab, Settings): source
/// sheet, access explainer, review, then the result snackbar with undo in
/// [messenger] (the People tab's own; defaults to the nearest). Completes
/// once that undo offer is gone (see [ImportResultReport.show]).
Future<void> startBirthdayImport(
  BuildContext context, {
  ScaffoldMessengerState? messenger,
}) async {
  final services = ImportServicesScope.of(context);
  final report = ImportResultReport(
    messenger: messenger ?? ScaffoldMessenger.of(context),
    l10n: AppLocalizations.of(context),
    services: services,
  );
  final navigator = Navigator.of(context);
  final pickerSupported = await services.picker.isSupported();
  if (!context.mounted) return;
  final choice = await showImportSourceSheet(
    context,
    pickerSupported: pickerSupported,
  );
  if (choice == null || !context.mounted) return;
  final wasEmpty = (await FriendsService.getAllFriends()).isEmpty;
  if (!context.mounted) return;
  final screen = await _screenFor(context, choice, services, report);
  if (screen == null) return;
  final outcome = await navigator.push<ImportOutcome>(
    MaterialPageRoute(builder: (_) => screen),
  );
  if (outcome != null) await report.show(outcome, firstPeople: wasEmpty);
}

Future<Widget?> _screenFor(
  BuildContext context,
  ImportSourceChoice choice,
  ImportServices services,
  ImportResultReport report,
) {
  return switch (choice) {
    ImportSourceChoice.allContacts => _contactsScreen(
      context,
      services,
      vcardScreen: () => _vcardScreen(services, report),
    ),
    ImportSourceChoice.pickContacts => _pickedScreen(services),
    ImportSourceChoice.vcard => _vcardScreen(services, report),
  };
}

/// Explains before the system prompt (only while undecided), then asks.
/// [vcardScreen] is offered when access is refused.
Future<Widget?> _contactsScreen(
  BuildContext context,
  ImportServices services, {
  required Future<Widget?> Function() vcardScreen,
}) async {
  var access = await services.contacts.access();
  if (access == ContactsAccess.notDetermined) {
    if (!context.mounted || !await showContactsExplainer(context)) return null;
    access = await services.contacts.requestAccess();
  }
  return ContactsImportScreen(
    services: services,
    initialAccess: access,
    vcardScreen: vcardScreen,
  );
}

/// The system contact picker; null when cancelled.
Future<Widget?> _pickedScreen(ImportServices services) async {
  final picked = await services.picker.pickContacts();
  if (picked.isEmpty) return null;
  return ImportReviewScreen(
    load: () async => ImportFound(
      candidates: picked.candidates,
      sourceWithoutBirthday: picked.withoutBirthday,
    ),
    services: services,
  );
}

/// The picked .vcf file, already parsed; null when cancelled or unreadable
/// (reported in a snackbar).
Future<Widget?> _vcardScreen(
  ImportServices services,
  ImportResultReport report,
) async {
  try {
    final parsed = await services.vcard.pickAndParse();
    if (parsed == null) return null;
    return ImportReviewScreen(
      load: () async =>
          ImportFound(candidates: parsed.candidates, vcard: parsed),
      services: services,
      vcard: true,
    );
  } on VCardFileException catch (e) {
    report.fileProblem(e.problem);
    return null;
  }
}
