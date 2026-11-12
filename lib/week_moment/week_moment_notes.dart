import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';

/// Saves what the user writes in the weekly moment's closing steps into
/// the Compass: what was beautiful as a lived moment, the one thing for the
/// next week as a "Now" intention. Blank texts save nothing. Injectable
/// into the screen (tests record instead).
class WeekMomentNotes {
  const WeekMomentNotes();

  /// [text] (trimmed) as the text to save, or null when it is blank.
  static String? savable(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Saves [text] as a lived moment on [day]; null when [text] is blank.
  Future<Moment?> keepMoment(String text, {required DateTime day}) async {
    final title = savable(text);
    if (title == null) return null;
    return CompassService.addMoment(title: title, date: compassDate(day));
  }

  /// Adds [text] as a "Now" intention on [day] ("Someday" when "Now" is
  /// full, see [AddIntentionResult.nowLimitReached]); null when blank.
  Future<AddIntentionResult?> planIntention(
    String text, {
    required DateTime day,
  }) async {
    final title = savable(text);
    if (title == null) return null;
    return CompassService.addIntention(title: title, today: day);
  }
}
