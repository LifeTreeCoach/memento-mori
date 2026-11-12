/// When the gentle "support the app" card on the Life tab is due.
///
/// Milestones, counted from the first use of the app:
/// 1. 30 days,
/// 2. 6 calendar months,
/// 3. then yearly after that: 18, 30, 42, … calendar months.
///
/// Calendar months (not 182 days) so the prompts land on the same day of
/// the month as the first use; a day that doesn't exist in the target month
/// is clamped to its last day (31 Aug + 6 months = 28/29 Feb).
///
/// The next due date is the first milestone strictly after the last time
/// the card was shown, so missed milestones collapse into one prompt and
/// the card never comes twice in a row. Pure and date-only.
class SupportPrompt {
  const SupportPrompt._();

  static const int firstPromptDays = 30;
  static const int secondPromptMonths = 6;
  static const int monthsBetweenLaterPrompts = 12;

  /// The next date the card is due, or null when the user opted out or
  /// already supported the app.
  static DateTime? nextDue({
    required DateTime firstUse,
    DateTime? lastShown,
    bool optedOut = false,
    bool alreadySupported = false,
  }) {
    if (optedOut || alreadySupported) return null;
    final shown = lastShown == null ? null : dateOnly(lastShown);
    for (var index = 0; ; index++) {
      final due = milestone(firstUse, index);
      if (shown == null || due.isAfter(shown)) return due;
    }
  }

  /// Whether the card is due on [today].
  static bool isDue({
    required DateTime today,
    required DateTime firstUse,
    DateTime? lastShown,
    bool optedOut = false,
    bool alreadySupported = false,
  }) {
    final due = nextDue(
      firstUse: firstUse,
      lastShown: lastShown,
      optedOut: optedOut,
      alreadySupported: alreadySupported,
    );
    return due != null && !dateOnly(today).isBefore(due);
  }

  /// The [index]-th milestone (0 = 30 days, 1 = 6 months, 2 = 18 months, …).
  static DateTime milestone(DateTime firstUse, int index) {
    final start = dateOnly(firstUse);
    if (index == 0) {
      return DateTime(start.year, start.month, start.day + firstPromptDays);
    }
    final months = secondPromptMonths + (index - 1) * monthsBetweenLaterPrompts;
    return addMonths(start, months);
  }

  /// [date] plus [months] calendar months, the day clamped to the month.
  static DateTime addMonths(DateTime date, int months) {
    final firstOfMonth = DateTime(date.year, date.month + months);
    final lastDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(firstOfMonth.year, firstOfMonth.month, day);
  }

  /// How long the app has been in use on [today], for the card's text.
  static SupportUsage usage({
    required DateTime firstUse,
    required DateTime today,
  }) {
    final start = dateOnly(firstUse);
    final day = dateOnly(today);
    var months = 0;
    while (!addMonths(start, months + 1).isAfter(day)) {
      months++;
    }
    if (months < secondPromptMonths) return const SupportUsage.month();
    if (months < 12) return const SupportUsage.halfYear();
    return SupportUsage.years(months ~/ 12);
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// "a month", "half a year" or a number of whole years.
class SupportUsage {
  const SupportUsage.month() : years = 0, halfYear = false;
  const SupportUsage.halfYear() : years = 0, halfYear = true;
  const SupportUsage.years(this.years) : halfYear = false;

  /// Whole years of use; 0 for "a month" and "half a year".
  final int years;
  final bool halfYear;

  @override
  bool operator ==(Object other) =>
      other is SupportUsage &&
      other.years == years &&
      other.halfYear == halfYear;

  @override
  int get hashCode => Object.hash(years, halfYear);

  @override
  String toString() => 'SupportUsage(years: $years, halfYear: $halfYear)';
}
