import 'package:memento_mori_life_in_weeks/localization.dart';

/// Stored group values of People: the predefined groups are kept as
/// language-neutral ids (`@family`, `@friends`) and shown with their
/// localized label; custom groups are stored and shown as typed.
class GroupNames {
  GroupNames._();

  static const String family = '@family';
  static const String friends = '@friends';

  /// Predefined group ids, in display order.
  static const List<String> predefined = [family, friends];

  /// Localization key of each predefined id.
  static const Map<String, String> _labelKeys = {
    family: 'group_family',
    friends: 'group_friends',
  };

  static bool isPredefined(String stored) => _labelKeys.containsKey(stored);

  /// The text shown for the stored group value [stored].
  static String label(String stored, AppLocalizations l10n) {
    final key = _labelKeys[stored];
    return key == null ? stored : l10n.translate(key);
  }

  /// A labeler for [l10n], e.g. for [FriendQuery.groupLabel].
  static String Function(String) labelerFor(AppLocalizations l10n) =>
      (stored) => label(stored, l10n);

  /// The value to store for the typed [text]: trimmed, null when empty; the
  /// label of a predefined group in any supported language (ignoring case)
  /// becomes its id.
  static String? normalize(String? text) {
    final trimmed = text?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return predefinedIdFor(trimmed) ?? trimmed;
  }

  /// The id of the predefined group whose label in any supported language
  /// is [text] (trimmed, ignoring case); null for every other text.
  static String? predefinedIdFor(String text) =>
      _idsByFoldedLabel[text.trim().toLowerCase()];

  /// Predefined ids by their lower-case label in every supported language.
  static final Map<String, String> _idsByFoldedLabel = {
    for (final language in AppLocalizations.supportedLanguages)
      for (final entry in _labelKeys.entries)
        if (AppLocalizations.valuesFor(language)[entry.value] case final l?)
          l.toLowerCase(): entry.key,
  };
}
