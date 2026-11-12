/// The ordinal of a year of life ([n] >= 1) as written in [languageCode]:
/// "37th", "37.", "37e" (French "année" is feminine: "1re") or "37.º".
/// Unknown languages get the English form.
String yearOrdinal(int n, String languageCode) => switch (languageCode) {
  'de' => '$n.',
  'fr' => _frenchFeminineOrdinal(n),
  'es' => '$n.º',
  _ => _englishOrdinal(n),
};

String _frenchFeminineOrdinal(int n) => n == 1 ? '1re' : '${n}e';

String _englishOrdinal(int n) => '$n${_englishSuffix(n)}';

String _englishSuffix(int n) {
  final lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 13) return 'th';
  return switch (n % 10) {
    1 => 'st',
    2 => 'nd',
    3 => 'rd',
    _ => 'th',
  };
}
