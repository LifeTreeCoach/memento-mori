import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../localization.dart';
import '../contacts_source.dart';
import '../import_applier.dart';
import 'import_review_model.dart';
import 'import_review_screen.dart';
import 'import_review_states.dart';
import 'import_services.dart';

/// Import from all device contacts: the review once contacts can be read,
/// otherwise why not and how to allow it. Access is checked again when the
/// app comes back from the system settings; with limited access (iOS 18) the
/// review is read again then, as more contacts may have been shared.
class ContactsImportScreen extends StatefulWidget {
  const ContactsImportScreen({
    super.key,
    required this.services,
    required this.initialAccess,
    this.vcardScreen,
  });

  final ImportServices services;
  final ContactsAccess initialAccess;

  /// The vCard review offered as the way around refused access; null when
  /// cancelled or unreadable. Without it no vCard button is shown.
  final Future<Widget?> Function()? vcardScreen;

  @override
  State<ContactsImportScreen> createState() => _ContactsImportScreenState();
}

class _ContactsImportScreenState extends State<ContactsImportScreen>
    with WidgetsBindingObserver {
  late ContactsAccess _access = widget.initialAccess;

  /// Bumped to make the review read the contacts again.
  final _reload = ValueNotifier<int>(0);

  ContactsSource get _contacts => widget.services.contacts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reload.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_access.canRead) {
      _recheck();
    } else if (_access == ContactsAccess.limited) {
      _reloadShared();
    }
  }

  /// After "Share more": the shared contacts (or the access) may differ.
  Future<void> _reloadShared() async {
    await _recheck();
    if (mounted && _access.canRead) _reload.value++;
  }

  Future<void> _recheck() => _update(_contacts.access());

  Future<void> _askAgain() => _update(_contacts.requestAccess());

  Future<void> _update(Future<ContactsAccess> next) async {
    final access = await next;
    if (mounted && access != _access) setState(() => _access = access);
  }

  Future<ImportFound> _load() async =>
      ImportFound(candidates: await _contacts.readBirthdays(), access: _access);

  @override
  Widget build(BuildContext context) {
    if (_access.canRead) {
      return ImportReviewScreen(
        load: _load,
        services: widget.services,
        reload: _reload,
      );
    }
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('import_birthdays'))),
      body: ImportMessageState(
        icon: Icons.contacts_outlined,
        title: l10n.translate('import_denied_title'),
        body: l10n.translate(_bodyKey),
        actions: [?_action(l10n), ?_vcardAction(l10n)],
      ),
    );
  }

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// iOS reports a first "Don't Allow" as permanently denied, so it gets a
  /// softer text that also points to the vCard route.
  String get _bodyKey => switch (_access) {
    ContactsAccess.permanentlyDenied when _isIOS =>
      'import_denied_settings_body_ios',
    ContactsAccess.permanentlyDenied => 'import_denied_settings_body',
    ContactsAccess.restricted => 'import_restricted_body',
    _ => 'import_denied_body',
  };

  Widget? _action(AppLocalizations l10n) => switch (_access) {
    ContactsAccess.permanentlyDenied => FilledButton(
      key: const ValueKey('import-open-settings'),
      onPressed: _contacts.openSettings,
      child: Text(l10n.translate('import_open_settings')),
    ),
    ContactsAccess.restricted => null,
    _ => FilledButton(
      key: const ValueKey('import-ask-again'),
      onPressed: _askAgain,
      child: Text(l10n.translate('import_ask_again')),
    ),
  };

  /// "Choose a vCard file instead" wherever the text suggests it.
  Widget? _vcardAction(AppLocalizations l10n) {
    final suggested =
        _access == ContactsAccess.denied ||
        (_access == ContactsAccess.permanentlyDenied && _isIOS);
    if (widget.vcardScreen == null || !suggested) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextButton(
        key: const ValueKey('import-choose-vcard'),
        onPressed: _chooseVCard,
        child: Text(l10n.translate('import_choose_vcard')),
      ),
    );
  }

  /// Reviews a vCard file on top of this screen and hands its outcome on.
  Future<void> _chooseVCard() async {
    final screen = await widget.vcardScreen!();
    if (screen == null || !mounted) return;
    final outcome = await Navigator.of(context)
        .push<ImportOutcome>(MaterialPageRoute(builder: (_) => screen));
    if (outcome != null && mounted) Navigator.of(context).pop(outcome);
  }
}
