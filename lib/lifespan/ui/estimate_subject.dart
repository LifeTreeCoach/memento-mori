import 'package:memento_mori_life_in_weeks/localization.dart';

/// Whose lifespan the estimate is about: the user ([SelfSubject], addressed
/// as "you") or another person ([OtherSubject], named).
///
/// Texts that address "you" have a twin key with the suffix `_someone` that
/// names the person through `{name}` (in subject position, so no grammatical
/// gender is needed).
sealed class LifespanEstimateSubject {
  const LifespanEstimateSubject();

  /// Suffix of the keys addressing another person. Not `_other`: that
  /// suffix belongs to the plural forms (`AppLocalizations.plural`).
  static const String someoneSuffix = '_someone';

  /// The key for this subject: [base] or `base_someone`.
  String key(String base);

  /// Placeholders every subject text may use (`{name}`).
  Map<String, String> get replacements;

  bool get isSelf;

  /// Translates [base] for this subject, with [replacements] on top.
  String translate(
    AppLocalizations l10n,
    String base, {
    Map<String, String>? replacements,
  }) => l10n.translate(
    key(base),
    replacements: {...this.replacements, ...?replacements},
  );
}

/// The user's own estimate ("your years").
final class SelfSubject extends LifespanEstimateSubject {
  const SelfSubject();

  @override
  String key(String base) => base;

  @override
  Map<String, String> get replacements => const {};

  @override
  bool get isSelf => true;
}

/// Someone else's estimate, e.g. a friend's ("Ana's years").
final class OtherSubject extends LifespanEstimateSubject {
  const OtherSubject(this.name);

  final String name;

  @override
  String key(String base) => '$base${LifespanEstimateSubject.someoneSuffix}';

  @override
  Map<String, String> get replacements => {'name': name};

  @override
  bool get isSelf => false;

  @override
  bool operator ==(Object other) => other is OtherSubject && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// The keys that have a `_someone` twin (checked by the tests).
abstract final class SubjectKeys {
  static const List<String> all = [
    'estimate_title',
    'estimate_intro',
    'estimate_show_estimate',
    'estimate_load_failed',
    'estimate_prefer_not',
    'estimate_question_conditions',
    'estimate_hint_conditions',
    'estimate_conditions_note',
    'estimate_question_smoking',
    'estimate_hint_smoking',
    'estimate_question_activity',
    'estimate_hint_activity',
    'estimate_question_alcohol',
    'estimate_hint_alcohol',
    'estimate_question_bmi',
    'estimate_hint_bmi',
    'estimate_weight_result',
    'estimate_weight_privacy',
    'estimate_question_social',
    'estimate_hint_social',
    'estimate_result_label',
    'estimate_result_sentence',
    'estimate_your_number',
    'estimate_fine_tune_note',
  ];
}
