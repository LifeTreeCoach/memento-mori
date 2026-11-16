/// Password dialogs for protected backups.
library;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Shortest password accepted for a new protected backup.
const int minBackupPasswordLength = 8;

/// Asks for a new backup password (typed twice); null when cancelled.
Future<String?> showNewBackupPasswordDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _NewPasswordDialog(),
    );

/// Asks for the password of a protected backup; null when cancelled.
/// [wrongPassword] says the previous try did not open it.
Future<String?> showBackupPasswordDialog(
  BuildContext context, {
  bool wrongPassword = false,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _UnlockDialog(wrongPassword: wrongPassword),
    );

/// The problem with a new password pair, as a localization key; null if
/// it can be used.
String? newPasswordProblem(String password, String confirmation) {
  if (password.length < minBackupPasswordLength) {
    return 'import_export_password_too_short';
  }
  if (password != confirmation) return 'import_export_password_mismatch';
  return null;
}

class _NewPasswordDialog extends StatefulWidget {
  const _NewPasswordDialog();

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _problemKey;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    final problem = newPasswordProblem(_password.text, _confirmation.text);
    if (problem == null) {
      Navigator.of(context).pop(_password.text);
    } else {
      setState(() => _problemKey = problem);
    }
  }

  String? _problemText(AppLocalizations l10n) => switch (_problemKey) {
        null => null,
        final key => l10n.translate(key,
            replacements: {'n': '$minBackupPasswordLength'}),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.translate('import_export_password_new_title')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('import_export_password_warning'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _PasswordField(
            controller: _password,
            label: l10n.translate('import_export_password_label'),
            autofocus: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _confirmation,
            label: l10n.translate('import_export_password_confirm_label'),
            errorText: _problemText(l10n),
            onSubmitted: _submit,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('import_export_cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.translate('import_export_password_protect_button')),
        ),
      ],
    );
  }
}

class _UnlockDialog extends StatefulWidget {
  const _UnlockDialog({required this.wrongPassword});

  final bool wrongPassword;

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.isEmpty) return;
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.translate('import_export_password_unlock_title')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.translate('import_export_password_unlock_body')),
          const SizedBox(height: 16),
          _PasswordField(
            controller: _password,
            label: l10n.translate('import_export_password_label'),
            autofocus: true,
            errorText: widget.wrongPassword
                ? l10n.translate('import_export_password_wrong')
                : null,
            onSubmitted: _submit,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('import_export_cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.translate('import_export_password_unlock_button')),
        ),
      ],
    );
  }
}

/// Obscured text field with a show/hide toggle.
class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    this.errorText,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool autofocus;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: widget.controller,
      obscureText: !_visible,
      autofocus: widget.autofocus,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.textInputAction,
      onSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        errorMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: l10n.translate(_visible
              ? 'import_export_password_hide'
              : 'import_export_password_show'),
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}
