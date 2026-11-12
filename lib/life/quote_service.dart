import 'package:memento_mori_life_in_weeks/life/life_stage.dart';
import 'package:memento_mori_life_in_weeks/life/quotes/quote_data.dart';
import 'package:memento_mori_life_in_weeks/life/quotes/quote_entry.dart';

/// A quote resolved to one language.
class Quote {
  const Quote({
    required this.id,
    required this.text,
    this.author,
    this.source,
  });

  /// Stable id, the same in every language.
  final String id;
  final String text;

  /// Null for the anonymous app quotes.
  final String? author;

  /// Work and passage, e.g. "De Brevitate Vitae 1.3"; null when anonymous.
  final String? source;
}

/// The daily life quote of the Life tab's quote card.
///
/// All languages share one collection ([quoteEntries]), so a given day shows
/// the same quote in every language.
class QuoteService {
  static const String _fallbackLanguage = 'en';

  /// Days are counted from this date, so there is no reset on Jan 1.
  static final DateTime _epoch = DateTime.utc(2000);

  /// Fixed seed of the shuffled base order; changing it reorders every day.
  static const int _shuffleSeed = 0x4D656D6F; // "Memo"

  static final List<int> _baseOrder = _shuffledIndices(quoteEntries.length);
  static final Map<LifeStage?, List<int>> _cycles = {};

  /// All life quotes in [language], in collection order (same set and order
  /// for every language; unknown languages fall back to English).
  static List<Quote> lifeQuotes(String language) =>
      [for (final entry in quoteEntries) resolve(entry, language)];

  /// [entry] in [language] (English when the language is missing).
  static Quote resolve(QuoteEntry entry, String language) {
    String pick(Map<String, String> values) =>
        values[language] ?? values[_fallbackLanguage]!;
    final author = entry.author;
    return Quote(
      id: entry.id,
      text: pick(entry.text),
      author: author == null ? null : pick(author),
      source: entry.source,
    );
  }

  /// The same quote all day, the next one of the cycle the next day.
  ///
  /// With [ageYears], quotes for the user's life stage appear twice per
  /// cycle; every quote still appears at least once.
  static Quote quoteOfTheDay(String language, {DateTime? date, int? ageYears}) {
    final stage = ageYears == null ? null : LifeStage.fromAge(ageYears);
    final cycle = cycleFor(stage);
    final index = cycle[daysSinceEpoch(date ?? DateTime.now()) % cycle.length];
    return resolve(quoteEntries[index], language);
  }

  /// Calendar days from the fixed epoch to [date] (time of day ignored).
  static int daysSinceEpoch(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).difference(_epoch).inDays;

  /// Indices into [quoteEntries] for one cycle: the shuffled base order, with
  /// a second copy of each [stage] quote half a cycle after its first one.
  static List<int> cycleFor(LifeStage? stage) =>
      _cycles.putIfAbsent(stage, () => _buildCycle(stage));

  static List<int> _buildCycle(LifeStage? stage) {
    final count = _baseOrder.length;
    final repeatsAfter = <int, List<int>>{};
    if (stage != null) {
      for (var position = 0; position < count; position++) {
        final index = _baseOrder[position];
        if (!quoteEntries[index].stages.contains(stage)) continue;
        final slot = (position + count ~/ 2) % count;
        repeatsAfter.putIfAbsent(slot, () => []).add(index);
      }
    }
    return [
      for (var position = 0; position < count; position++) ...[
        _baseOrder[position],
        ...?repeatsAfter[position],
      ],
    ];
  }

  /// Fisher-Yates shuffle of 0..count-1 with a fixed xorshift32 generator,
  /// so the order is identical on every platform and run.
  static List<int> _shuffledIndices(int count) {
    final indices = List<int>.generate(count, (i) => i);
    var state = _shuffleSeed;
    int next() {
      state ^= (state << 13) & 0xFFFFFFFF;
      state ^= state >> 17;
      state ^= (state << 5) & 0xFFFFFFFF;
      return state;
    }

    for (var i = count - 1; i > 0; i--) {
      final j = next() % (i + 1);
      final swap = indices[i];
      indices[i] = indices[j];
      indices[j] = swap;
    }
    return indices;
  }
}
