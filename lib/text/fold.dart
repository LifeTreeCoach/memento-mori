/// Accent- and case-insensitive text folding, shared by sorting (country
/// names) and matching (people import).
library;

const Map<String, String> _foldings = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'æ': 'ae',
  'ç': 'c',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ø': 'o',
  'œ': 'oe',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ß': 'ss',
  '’': "'",
};

/// Lower-cases [text] and strips Latin diacritics ("Jörg" -> "jorg",
/// "Straße" -> "strasse"), for accent-insensitive sorting and comparing.
String foldText(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(_foldings[char] ?? char);
  }
  return buffer.toString();
}
