import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../widgets/scroll_thread.dart';

/// Progress while the source is read.
class ImportLoadingState extends StatelessWidget {
  const ImportLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).translate('import_loading')),
        ],
      ),
    );
  }
}

/// A calm message with an icon, used for "no birthdays found", read errors
/// and missing contacts access; [actions] go below the text.
class ImportMessageState extends StatelessWidget {
  const ImportMessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScrollThread(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (actions.isNotEmpty) const SizedBox(height: 24),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// "No birthdays found" with tips for the source ([vcard] or contacts).
/// With [onShareMore] (limited contacts access) it says that only selected
/// contacts were shared and offers to share more.
class ImportEmptyState extends StatelessWidget {
  const ImportEmptyState({super.key, required this.vcard, this.onShareMore});

  final bool vcard;
  final VoidCallback? onShareMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shareMore = onShareMore;
    return ImportMessageState(
      icon: Icons.cake_outlined,
      title: l10n.translate('import_empty_title'),
      body: l10n.translate(_bodyKey),
      actions: [
        if (shareMore != null)
          FilledButton(
            key: const ValueKey('import-empty-share-more'),
            onPressed: shareMore,
            child: Text(l10n.translate('import_limited_action')),
          ),
      ],
    );
  }

  String get _bodyKey {
    if (vcard) return 'import_empty_vcard_tips';
    return onShareMore != null ? 'import_empty_limited' : 'import_empty_tips';
  }
}
