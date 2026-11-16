import 'package:flutter/material.dart';

import '../../localization.dart';
import '../personal_store.dart';

/// Tells the user when personal data could not be saved (e.g. the disk is
/// full) and offers to save it again.
///
/// Placed in `MaterialApp.builder`, so it sits below the app's
/// [ScaffoldMessenger] and the snackbar shows on every screen. The message
/// stays until it is acted on or the data is saved; it is shown once while
/// it is visible, however many writes fail meanwhile.
class UnsavedChangesNotice extends StatefulWidget {
  const UnsavedChangesNotice({
    super.key,
    required this.store,
    required this.child,
  });

  final PersonalStore store;
  final Widget child;

  @override
  State<UnsavedChangesNotice> createState() => _UnsavedChangesNoticeState();
}

class _UnsavedChangesNoticeState extends State<UnsavedChangesNotice> {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _problem;

  bool get _hasUnsaved => widget.store.hasUnsavedChanges.value;

  @override
  void initState() {
    super.initState();
    widget.store.hasUnsavedChanges.addListener(_onUnsavedChanged);
    if (_hasUnsaved) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onUnsavedChanged());
    }
  }

  @override
  void didUpdateWidget(UnsavedChangesNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.store, widget.store)) return;
    oldWidget.store.hasUnsavedChanges.removeListener(_onUnsavedChanged);
    widget.store.hasUnsavedChanges.addListener(_onUnsavedChanged);
  }

  @override
  void dispose() {
    widget.store.hasUnsavedChanges.removeListener(_onUnsavedChanged);
    super.dispose();
  }

  void _onUnsavedChanged() {
    if (!mounted) return;
    if (_hasUnsaved) {
      _showProblem();
    } else {
      _problem?.close();
    }
  }

  void _showProblem() {
    if (_problem != null) return;
    final l10n = AppLocalizations.of(context);
    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('vault_unsaved_message')),
        // An action keeps it on screen until it is used or dismissed.
        action: SnackBarAction(
          label: l10n.translate('vault_unsaved_retry'),
          onPressed: _retry,
        ),
      ),
    );
    _problem = controller;
    controller.closed.then((reason) => _onProblemClosed(controller, reason));
  }

  /// Another snackbar pushed it aside: it comes back after that one while
  /// the data is still unsaved. Dismissed by the user: it stays away until
  /// the next time saving fails.
  void _onProblemClosed(
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller,
    SnackBarClosedReason reason,
  ) {
    if (!identical(_problem, controller)) return;
    _problem = null;
    final displaced = reason == SnackBarClosedReason.hide ||
        reason == SnackBarClosedReason.remove;
    if (displaced && mounted && _hasUnsaved) _showProblem();
  }

  Future<void> _retry() async {
    _problem = null;
    final saved = await widget.store.retryUnsaved();
    if (!mounted) return;
    if (saved && !_hasUnsaved) {
      _showSaved();
    } else {
      _showProblem();
    }
  }

  void _showSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('vault_unsaved_saved'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
