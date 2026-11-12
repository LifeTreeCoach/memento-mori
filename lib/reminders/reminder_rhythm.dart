/// How often the Compass reminds: the Sunday question every week, a phase
/// check-in every 4 weeks, or never. Replaces the weekly reminder switch.
enum ReminderRhythm {
  weekly('weekly'),
  every4Weeks('every_4_weeks'),
  off('off');

  const ReminderRhythm(this.id);

  /// Stored value.
  final String id;

  /// The rhythm stored as [id], or null if unknown.
  static ReminderRhythm? fromId(String? id) {
    for (final rhythm in values) {
      if (rhythm.id == id) return rhythm;
    }
    return null;
  }

  /// Rhythm of the legacy `weekly_reminder_enabled` switch (missing = on).
  static ReminderRhythm fromLegacyEnabled(bool? enabled) =>
      enabled == false ? off : weekly;

  /// Whether any reminder is on (the value of the legacy switch).
  bool get isOn => this != off;
}
