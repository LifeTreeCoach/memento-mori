import 'package:flutter/material.dart';

import '../../localization.dart';
import '../contacts_source.dart';
import 'import_review_model.dart';

/// Counts ("42 birthdays found · 3 already there", vCard skips), the
/// limited-access note, the search field and "All / None" (only while
/// something can be ticked).
class ImportReviewHeader extends StatelessWidget {
  const ImportReviewHeader({
    super.key,
    required this.model,
    required this.found,
    required this.searchController,
    required this.onOpenSettings,
  });

  final ImportReviewModel model;
  final ImportFound found;
  final TextEditingController searchController;
  final VoidCallback onOpenSettings;

  /// The header line for [model] and [found], e.g.
  /// "42 birthdays found · 3 already there · 5 without birthday".
  static String summary(
    AppLocalizations l10n,
    ImportReviewModel model,
    ImportFound found,
  ) {
    final vcard = found.vcard;
    final skipped = vcard == null
        ? 0
        : vcard.invalidBirthday + vcard.withoutName;
    return [
      l10n.plural('import_found', model.foundCount),
      if (model.alreadyCount > 0)
        l10n.plural('import_already', model.alreadyCount),
      if (found.withoutBirthday > 0)
        l10n.plural('import_without_birthday', found.withoutBirthday),
      if (skipped > 0) l10n.plural('import_skipped', skipped),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary(l10n, model, found), style: theme.textTheme.titleMedium),
          if (!model.hasSelectable)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(l10n.translate('import_all_there')),
            ),
          if (found.access == ContactsAccess.limited) _limitedNote(l10n, theme),
          if (model.hasSelectable) ...[
            const SizedBox(height: 12),
            _searchRow(l10n),
          ],
        ],
      ),
    );
  }

  Widget _limitedNote(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
          Text(l10n.translate('import_limited_note')),
          TextButton(
            onPressed: onOpenSettings,
            child: Text(l10n.translate('import_limited_action')),
          ),
        ],
      ),
    );
  }

  Widget _searchRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.translate('import_search_hint'),
            ),
          ),
        ),
        TextButton(
          onPressed: () => model.selectAllVisible(true),
          child: Text(l10n.translate('import_select_all')),
        ),
        TextButton(
          onPressed: () => model.selectAllVisible(false),
          child: Text(l10n.translate('import_select_none')),
        ),
      ],
    );
  }
}
