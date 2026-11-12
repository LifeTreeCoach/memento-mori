import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../people/sheet_title.dart';
import '../../widgets/scroll_thread.dart';

/// Explains what the app reads before the system asks for the contacts
/// permission (shown only while access is undecided). True = continue.
Future<bool> showContactsExplainer(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const ContactsExplainerSheet(),
  );
  return confirmed ?? false;
}

/// Content of [showContactsExplainer].
class ContactsExplainerSheet extends StatelessWidget {
  const ContactsExplainerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SafeArea(
      child: ScrollThread(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.contacts_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              SheetTitle(l10n.translate('import_explainer_title')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.translate('import_explainer_body'),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.translate('import_explainer_ios_choice'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.translate('import_privacy'),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
              const SizedBox(height: 20),
              _actions(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('import_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('import_continue')),
          ),
        ],
      ),
    );
  }
}
