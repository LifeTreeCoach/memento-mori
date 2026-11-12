/// Regex parsers and parity checks for the native string files
/// (Android `strings.xml`, iOS `InfoPlist.strings`). Pure functions, so the
/// checks are unit-tested with bad fixtures as well.
library;

import 'translation_checks.dart';

/// The `<string>` and `<plurals>` resources of one Android `strings.xml`.
class AndroidStrings {
  const AndroidStrings(this.strings, this.plurals);

  /// name -> raw value.
  final Map<String, String> strings;

  /// name -> quantity -> raw value.
  final Map<String, Map<String, String>> plurals;

  /// Every text, keyed `name` or `name[quantity]`.
  Map<String, String> get allTexts => {
    ...strings,
    for (final plural in plurals.entries)
      for (final item in plural.value.entries)
        '${plural.key}[${item.key}]': item.value,
  };
}

final _xmlComment = RegExp(r'<!--.*?-->', dotAll: true);
final _string = RegExp(
  r'<string\s+name="([^"]+)"[^>]*?(?:/>|>(.*?)</string>)',
  dotAll: true,
);
final _plurals = RegExp(
  r'<plurals\s+name="([^"]+)"[^>]*>(.*?)</plurals>',
  dotAll: true,
);
final _item = RegExp(
  r'<item\s+quantity="(\w+)"[^>]*?(?:/>|>(.*?)</item>)',
  dotAll: true,
);

AndroidStrings parseAndroidStrings(String xml) {
  final source = xml.replaceAll(_xmlComment, '');
  return AndroidStrings(
    {for (final m in _string.allMatches(source)) m.group(1)!: m.group(2) ?? ''},
    {
      for (final m in _plurals.allMatches(source))
        m.group(1)!: {
          for (final item in _item.allMatches(m.group(2)!))
            item.group(1)!: item.group(2) ?? '',
        },
    },
  );
}

final _escapedPercent = RegExp(r'%%');
final _formatArg = RegExp(r'%(?:\d+\$)?[-#+ 0,(]*\d*(?:\.\d+)?[sdfxXc]');

/// Android/Java format arguments of [text] (`%1$s`, `%d`, ...), sorted.
List<String> formatArgs(String text) =>
    _formatArg
        .allMatches(text.replaceAll(_escapedPercent, ''))
        .map((m) => m.group(0)!)
        .toList()
      ..sort();

/// Problems of [other] (labelled [label]) against the reference [en]:
/// different names, missing `one`/`other` plural forms, format arguments
/// that differ from English, and blank values.
List<String> androidParityProblems(
  String label,
  AndroidStrings en,
  AndroidStrings other,
) {
  return [
    ..._keyDifferences('$label strings', en.strings.keys, other.strings.keys),
    ..._keyDifferences('$label plurals', en.plurals.keys, other.plurals.keys),
    for (final plural in other.plurals.entries)
      for (final quantity in const ['one', 'other'])
        if (!plural.value.containsKey(quantity))
          '$label ${plural.key}: no "$quantity" item',
    for (final entry in other.strings.entries)
      if (en.strings.containsKey(entry.key))
        ..._argProblems(
          '$label ${entry.key}',
          en.strings[entry.key]!,
          entry.value,
        ),
    for (final plural in other.plurals.entries)
      for (final item in plural.value.entries)
        if (en.plurals[plural.key]?['other'] case final reference?)
          ..._argProblems(
            '$label ${plural.key}[${item.key}]',
            reference,
            item.value,
          ),
    for (final key in blankValues(other.allTexts)) '$label $key: empty',
  ];
}

List<String> _argProblems(String label, String reference, String text) {
  final expected = formatArgs(reference);
  final actual = formatArgs(text);
  return expected.join() == actual.join()
      ? const []
      : ['$label: format arguments $actual, English has $expected'];
}

final _cComment = RegExp(
  r'/\*.*?\*/|^\s*//[^\n]*',
  dotAll: true,
  multiLine: true,
);
final _iosEntry = RegExp(r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;');

/// key -> value of an iOS `.strings` file.
Map<String, String> parseIosStrings(String source) => {
  for (final m in _iosEntry.allMatches(source.replaceAll(_cComment, '')))
    m.group(1)!: m.group(2)!,
};

/// Problems of [other] (labelled [label]) against the reference [en]:
/// different keys and blank values.
List<String> iosParityProblems(
  String label,
  Map<String, String> en,
  Map<String, String> other,
) => [
  ..._keyDifferences(label, en.keys, other.keys),
  for (final key in blankValues(other)) '$label $key: empty',
];

List<String> _keyDifferences(
  String label,
  Iterable<String> en,
  Iterable<String> other,
) {
  final expected = en.toSet();
  final actual = other.toSet();
  return [
    for (final key in expected.difference(actual)) '$label: $key missing',
    for (final key in actual.difference(expected)) '$label: $key not in en',
  ];
}
