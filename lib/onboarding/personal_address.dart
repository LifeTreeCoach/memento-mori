import 'package:memento_mori_life_in_weeks/localization.dart';

/// How the onboarding addresses the user: by the name typed on its first
/// step, or plainly when none was given.
///
/// Texts that greet the user have a twin key with the suffix `_named` that
/// adds the name through `{name}`.
class PersonalAddress {
  /// Addresses [name], trimmed; a blank name gives the plain texts.
  PersonalAddress(String name) : this._(name.trim());

  const PersonalAddress._(this.name);

  /// No name: the plain texts.
  static const PersonalAddress none = PersonalAddress._('');

  /// Suffix of the keys that greet the user by name. Not `_other` or `_one`
  /// (plural forms, `AppLocalizations.plural`) and not `_someone` (texts
  /// about another person, `LifespanEstimateSubject`).
  static const String namedSuffix = '_named';

  /// The keys that have a `_named` twin (checked by the tests).
  static const List<String> keys = [
    'onboarding_estimate_title',
    'onboarding_reveal_tagline',
    'week_moment_close_title',
  ];

  /// The trimmed name; empty without one.
  final String name;

  bool get hasName => name.isNotEmpty;

  /// The key for this address: [base] or `base_named`.
  String key(String base) => hasName ? '$base$namedSuffix' : base;

  /// Translates [base] for this address, with [replacements] on top.
  String translate(
    AppLocalizations l10n,
    String base, {
    Map<String, String>? replacements,
  }) => l10n.translate(
    key(base),
    replacements: {if (hasName) 'name': name, ...?replacements},
  );
}
