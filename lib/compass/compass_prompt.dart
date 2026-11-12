import 'package:memento_mori_life_in_weeks/life/life_stage.dart';

/// What a Compass text is for.
enum CompassPromptKind {
  /// Weekly question about something put off out of fear (at most every
  /// other week, never with "gentle only").
  courage,

  /// Weekly question about people.
  connection,

  /// Weekly question about rest and enough.
  rest,

  /// Weekly question about something already done well.
  pride,

  /// Compassionate note; may contain `{weeks}`.
  note,

  /// Hint shown when "Now" is full.
  limit;

  /// The kinds asked as weekly questions without courage.
  static const List<CompassPromptKind> gentle = [connection, rest, pride];
}

/// What answering a question could become.
enum CompassSuggestion { intention, moment }

/// One Compass text with its translations (generated into
/// `compass_prompts.dart` from `tool/compass/prompts.json`).
class CompassPrompt {
  const CompassPrompt({
    required this.id,
    required this.kind,
    required this.text,
    this.stages = const [],
    this.suggestion,
    this.phase = false,
    this.topic,
  });

  /// Stable id, e.g. `courage_busy_work`.
  final String id;
  final CompassPromptKind kind;

  /// Text per language code (en, de, fr, es).
  final Map<String, String> text;

  /// Life stages this prompt speaks to (empty = any).
  final List<LifeStage> stages;

  /// Whether an answer fits an intention or a moment; null = just reflect.
  final CompassSuggestion? suggestion;

  /// Whether this question names the current life phase through `{phase}`;
  /// asked only while a phase is lived.
  final bool phase;

  /// Optional topic per language code, shown in the question's eyebrow
  /// instead of the kind's name (e.g. "Small gestures").
  final Map<String, String>? topic;

  bool fitsStage(LifeStage stage) => stages.isEmpty || stages.contains(stage);

  /// Whether this prompt may be asked at [stage]: phase questions only
  /// while a phase is lived ([hasPhase]).
  bool fits(LifeStage stage, {required bool hasPhase}) =>
      fitsStage(stage) && (hasPhase || !phase);

  /// Topic in [language] (English if missing); null without a topic.
  String? topicFor(String language) => topic?[language] ?? topic?['en'];

  /// Text in [language] (English if missing) with `{key}` placeholders
  /// replaced from [replacements].
  String textFor(String language, {Map<String, String> replacements = const {}}) {
    var result = text[language] ?? text['en']!;
    replacements.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
