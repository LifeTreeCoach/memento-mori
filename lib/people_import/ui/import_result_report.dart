import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../reminders/reminder_service.dart';
import '../../widgets/action_snack_bar.dart';
import '../import_applier.dart';
import '../vcard_source.dart';
import 'import_services.dart';

/// Tells the user what an import did: "38 people added" with undo, or
/// "No new birthdays"; also file problems of a picked vCard.
class ImportResultReport {
  /// How long the import's undo offer stays: one tap undoes a whole batch.
  static const Duration importUndoDuration = bulkActionSnackBarDuration;

  const ImportResultReport({
    required this.messenger,
    required this.l10n,
    required this.services,
  });

  final ScaffoldMessengerState messenger;
  final AppLocalizations l10n;
  final ImportServices services;

  /// Shows the result of [outcome]. After the first people ever
  /// ([firstPeople]) the notification permission is asked once, as when
  /// the first person is added by hand; that happens first, so the
  /// permission dialog never covers the undo offer. Completes once the
  /// undo offer is gone (timed out, used or replaced), so callers can hold
  /// back overlays such as a tour that would cover it.
  Future<void> show(ImportOutcome outcome, {required bool firstPeople}) async {
    if (!messenger.mounted) return;
    if (outcome.isEmpty) {
      _plain(l10n.translate('import_nothing_new'));
      return;
    }
    if (_shouldAskPermission(outcome, firstPeople)) {
      await services.requestNotificationPermission();
    }
    await _offerUndo(outcome);
  }

  bool _shouldAskPermission(ImportOutcome outcome, bool firstPeople) =>
      firstPeople &&
      outcome.addedCount > 0 &&
      ReminderService.isBirthdayNotificationsEnabled();

  /// "38 people added" with undo, kept on screen for
  /// [importUndoDuration]; completes when it closed.
  Future<void> _offerUndo(ImportOutcome outcome) async {
    if (!messenger.mounted) return;
    final changed = outcome.addedCount + outcome.updatedCount;
    final controller = showActionSnackBar(
      messenger,
      text: l10n.plural('import_applied', changed),
      action: SnackBarAction(
        label: l10n.translate('people_undo'),
        onPressed: () => services.applier.undo(outcome),
      ),
      duration: importUndoDuration,
    );
    await controller.closed;
  }

  /// A picked vCard file that is too large, unreadable or no vCard.
  void fileProblem(VCardFileProblem problem) {
    _plain(
      l10n.translate(switch (problem) {
        VCardFileProblem.tooLarge => 'import_vcard_too_large',
        VCardFileProblem.unreadable => 'import_vcard_unreadable',
        VCardFileProblem.notVCard => 'import_vcard_not_vcard',
      }),
    );
  }

  void _plain(String text) {
    if (!messenger.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
