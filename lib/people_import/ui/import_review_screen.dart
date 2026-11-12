import 'package:flutter/material.dart';

import '../../friends_service.dart';
import '../../localization.dart';
import '../contacts_source.dart';
import '../existing_person.dart';
import '../import_matcher.dart';
import '../import_plan.dart';
import 'import_review_body.dart';
import 'import_review_model.dart';
import 'import_review_states.dart';
import 'import_services.dart';

/// Reads what [load] delivers, compares it with the saved people and lets
/// the user pick what to take over. Pops with the [ImportOutcome] of the
/// applied batch (empty when there was nothing new), or null on back.
class ImportReviewScreen extends StatefulWidget {
  const ImportReviewScreen({
    super.key,
    required this.load,
    required this.services,
    this.vcard = false,
    this.reload,
  });

  final Future<ImportFound> Function() load;
  final ImportServices services;

  /// Reads [load] again whenever it notifies (e.g. more contacts shared);
  /// the choices made so far stay for the candidates still there.
  final Listenable? reload;

  /// Whether the candidates come from a vCard file (empty-state tips).
  final bool vcard;

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  ImportFound? _found;
  ImportReviewModel? _model;
  List<String> _groups = const [];
  bool _failed = false;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    widget.reload?.addListener(_reread);
    _read();
  }

  @override
  void didUpdateWidget(ImportReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reload == widget.reload) return;
    oldWidget.reload?.removeListener(_reread);
    widget.reload?.addListener(_reread);
  }

  @override
  void dispose() {
    widget.reload?.removeListener(_reread);
    _model?.dispose();
    super.dispose();
  }

  void _reread() {
    if (!_applying) _read();
  }

  Future<void> _read() async {
    try {
      final found = await widget.load();
      final friends = await FriendsService.getAllFriends();
      final result = matchCandidates(
        found.candidates,
        friends.map(existingPersonFromFriend).toList(),
      );
      if (!mounted) return;
      final previous = _model;
      setState(() {
        _found = found;
        _failed = false;
        _model = ImportReviewModel(result)..carryOver(previous);
        _groups = _groupsOf(friends.map((f) => f.groupName));
      });
      // Disposed after the frame that stops listening to it.
      if (previous != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      }
    } catch (e) {
      debugPrint('Import source not read: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  static List<String> _groupsOf(Iterable<String?> names) => {
    for (final name in names)
      if (name != null && name.trim().isNotEmpty) name.trim(),
  }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  Future<void> _apply() async {
    final model = _model!;
    final plan = buildImportPlan(
      model.result.matches,
      model.selection,
      today: widget.services.today,
    );
    setState(() => _applying = true);
    try {
      final outcome = await widget.services.applier.apply(plan);
      if (mounted) Navigator.of(context).pop(outcome);
    } catch (e) {
      if (!mounted) return;
      setState(() => _applying = false);
      final text = AppLocalizations.of(context)
          .translate('import_apply_error', replacements: {'error': '$e'});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('import_review_title'))),
      body: _body(l10n),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_failed) {
      return ImportMessageState(
        icon: Icons.error_outline,
        title: l10n.translate('import_read_error'),
        body: l10n.translate(
          widget.vcard ? 'import_empty_vcard_tips' : 'import_empty_tips',
        ),
      );
    }
    final model = _model, found = _found;
    if (model == null || found == null) return const ImportLoadingState();
    if (model.foundCount == 0) {
      return ImportEmptyState(
        vcard: widget.vcard,
        onShareMore: found.access == ContactsAccess.limited
            ? widget.services.contacts.openSettings
            : null,
      );
    }
    return ImportReviewBody(
      model: model,
      found: found,
      existingGroups: _groups,
      applying: _applying,
      today: widget.services.today,
      onApply: _apply,
      onOpenSettings: widget.services.contacts.openSettings,
    );
  }
}
