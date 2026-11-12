/// Pure completeness checks for translated texts. Each returns a list of
/// readable problems (empty = fine), so tests can both assert on real data
/// and prove with bad fixtures that the check really catches gaps.
library;

bool isBlank(String? value) => value == null || value.trim().isEmpty;

/// Keys of [table] whose value is empty or whitespace, minus [allowed].
List<String> blankValues(
  Map<String, String> table, {
  Set<String> allowed = const {},
}) => [
  for (final entry in table.entries)
    if (isBlank(entry.value) && !allowed.contains(entry.key)) entry.key,
];

/// Languages of [languages] that [texts] (one text per language code, as in
/// quotes and Compass prompts) is missing or has blank, labelled with [id].
List<String> missingTranslations(
  String id,
  Map<String, String>? texts,
  List<String> languages,
) => [
  for (final code in languages)
    if (isBlank(texts?[code])) '$id: $code missing or empty',
];

final _appPlaceholder = RegExp(r'\{(\w+)\}');

/// `{name}` placeholders of [text].
Set<String> appPlaceholders(String text) =>
    _appPlaceholder.allMatches(text).map((m) => m.group(1)!).toSet();

/// Languages whose `{name}` placeholders differ from the first language's
/// in [texts], labelled with [id].
List<String> placeholderMismatches(String id, Map<String, String> texts) {
  if (texts.isEmpty) return const [];
  final reference = texts.entries.first;
  final expected = appPlaceholders(reference.value);
  return [
    for (final entry in texts.entries)
      if (!_sameSet(appPlaceholders(entry.value), expected))
        '$id: ${entry.key} has ${appPlaceholders(entry.value)}, '
            '${reference.key} has $expected',
  ];
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
