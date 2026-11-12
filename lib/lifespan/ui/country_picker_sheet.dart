import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/lifespan/country_names.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/sheet_title.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// Searchable country list; resolves to the picked life-table code.
Future<String?> showCountryPickerSheet(
  BuildContext context, {
  required CountryNames countries,
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _CountryPickerSheet(countries: countries, selected: selected),
  );
}

/// Codes whose name in [language] contains [query], ignoring case and accents.
List<String> filterCountries(
  CountryNames countries,
  String language,
  String query,
) {
  final all = countries.sortedCodes(language);
  final needle = CountryNames.foldForSort(query.trim());
  if (needle.isEmpty) return all;
  return [
    for (final code in all)
      if (CountryNames.foldForSort(countries.name(code, language))
          .contains(needle))
        code,
  ];
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.countries, required this.selected});

  final CountryNames countries;
  final String selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = l10n.locale.languageCode;
    final codes = filterCountries(widget.countries, language, _query);
    final insets = MediaQuery.viewInsetsOf(context);
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: Column(
          children: [
            SheetTitle(l10n.translate('estimate_country')),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: TextField(
                key: const ValueKey('lifespan_country_search'),
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.translate('estimate_country_search'),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: codes.isEmpty
                  ? _NoMatch(text: l10n.translate('estimate_country_none'))
                  : ScrollThread(
                      child: ListView.builder(
                        itemCount: codes.length,
                        itemBuilder: (context, index) =>
                            _row(context, codes[index], language),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String code, String language) {
    final l10n = AppLocalizations.of(context);
    final selected = code == widget.selected;
    final isWorld = code == CountryNames.worldCode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(widget.countries.name(code, language)),
      subtitle: isWorld
          ? Text(l10n.translate('estimate_country_world_hint'))
          : null,
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      selected: selected,
      onTap: () => Navigator.pop(context, code),
    );
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
