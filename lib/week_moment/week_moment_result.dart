/// How the weekly moment ended for its caller.
enum WeekMomentResult {
  /// It was not shown (disabled, no birth date, already shown, ...).
  notShown,

  /// "Plan the week" (with or without a written plan): the caller opens
  /// the Compass tab.
  continued,

  /// "Enjoy life", back or any other way out: the caller stays where it is.
  closed,
}
