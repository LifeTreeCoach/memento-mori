import 'package:memento_mori_life_in_weeks/life/life_stage.dart';

/// One quote of the collection with its text in every app language
/// (generated into `quote_data.dart` from `tool/quotes/quotes.json`).
class QuoteEntry {
  const QuoteEntry({
    required this.id,
    required this.text,
    this.author,
    this.source,
    this.themes = const [],
    this.stages = const [],
  });

  /// Stable id, e.g. `seneca_brev_1_3`.
  final String id;

  /// Text per language code (en, de, fr, es).
  final Map<String, String> text;

  /// Author name per language code; null for the anonymous app quotes.
  final Map<String, String>? author;

  /// Work and passage, e.g. "De Brevitate Vitae 1.3" (not translated).
  final String? source;

  /// Topics such as time, mortality, presence.
  final List<String> themes;

  /// Life stages this quote speaks to in particular (empty = any).
  final List<LifeStage> stages;
}
