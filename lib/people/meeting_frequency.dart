/// How often the user sees a friend, set in the "Together" view of the
/// friend detail screen. Stored by [name] in the friend JSON
/// (`meetingFrequency`, optional).
///
/// [perYear] is a rough average used to estimate the encounters left:
/// - [fewTimesYear]: about once a season (4 a year),
/// - [rarely]: about once every two years (0.5 a year).
enum MeetingFrequency {
  daily(365),
  weekly(52),
  monthly(12),
  fewTimesYear(4),
  yearly(1),
  rarely(0.5);

  const MeetingFrequency(this.perYear);

  /// Average encounters per year.
  final double perYear;

  /// The frequency stored as [value], or null if missing or unknown.
  static MeetingFrequency? tryParse(Object? value) {
    for (final frequency in values) {
      if (frequency.name == value) return frequency;
    }
    return null;
  }
}
