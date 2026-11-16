import 'dart:convert';

import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/people/meeting_frequency.dart';

class Friend {
  final String id;
  final String name;
  final DateTime birthDate;
  final String? avatarPath;
  final String? notes;
  final String? customNotificationMessage;
  final String? groupName;
  final int customLifespan;
  final DateTime createdDate;
  final DateTime lastUpdated;
  final bool isActive;
  /// Stable per-friend base for notification ids (0 = not yet assigned).
  final int notificationId;

  /// How often the user sees this friend (optional, set in the "Together"
  /// view); drives the encounters-left estimate.
  final MeetingFrequency? meetingFrequency;

  /// False for a birthday known only by day and month. [birthDate] then
  /// lies in [noYearStorageYear] (a leap year, so Feb 29 works) and every
  /// age-based helper returns null or stays neutral.
  final bool hasBirthYear;

  /// Where the person was imported from ([importSourceContacts] or
  /// [importSourceVcard]); null when entered by hand.
  final String? importSource;

  /// Contact id or vCard UID of that import, used to recognise the person
  /// on a later import.
  final String? importSourceId;

  /// The years the lifespan estimate for this person applied; null when
  /// [customLifespan] was set by hand only. Only this result is kept,
  /// never the estimate's answers. Kept (unused) while the birth year is
  /// unknown.
  final int? estimatedYears;

  /// Leap year that stores day and month of a birthday without a year.
  static const int noYearStorageYear = 2000;
  static const String importSourceContacts = 'contacts';
  static const String importSourceVcard = 'vcard';
  static const String estimatedYearsKey = 'estimatedYears';

  const Friend({
    required this.id,
    required this.name,
    required this.birthDate,
    this.avatarPath,
    this.notes,
    this.customNotificationMessage,
    this.groupName,
    this.customLifespan = LifeCalculator.defaultLifeExpectancyYears,
    required this.createdDate,
    required this.lastUpdated,
    this.isActive = true,
    this.notificationId = 0,
    this.meetingFrequency,
    this.hasBirthYear = true,
    this.importSource,
    this.importSourceId,
    this.estimatedYears,
  });

  Friend copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    String? avatarPath,
    String? notes,
    String? customNotificationMessage,
    String? groupName,
    int? customLifespan,
    DateTime? createdDate,
    DateTime? lastUpdated,
    bool? isActive,
    int? notificationId,
    MeetingFrequency? meetingFrequency,
    bool? hasBirthYear,
    String? importSource,
    String? importSourceId,
    int? estimatedYears,
    bool clearGroupName = false,
    bool clearMeetingFrequency = false,
    bool clearEstimatedYears = false,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      avatarPath: avatarPath ?? this.avatarPath,
      notes: notes ?? this.notes,
      customNotificationMessage: customNotificationMessage ?? this.customNotificationMessage,
      groupName: clearGroupName ? null : (groupName ?? this.groupName),
      customLifespan: customLifespan ?? this.customLifespan,
      createdDate: createdDate ?? this.createdDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
      notificationId: notificationId ?? this.notificationId,
      meetingFrequency: clearMeetingFrequency
          ? null
          : (meetingFrequency ?? this.meetingFrequency),
      hasBirthYear: hasBirthYear ?? this.hasBirthYear,
      importSource: importSource ?? this.importSource,
      importSourceId: importSourceId ?? this.importSourceId,
      estimatedYears: clearEstimatedYears
          ? null
          : (estimatedYears ?? this.estimatedYears),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthDate': encodeBirthDate(birthDate, hasYear: hasBirthYear),
      'avatarPath': avatarPath,
      'notes': notes,
      'customNotificationMessage': customNotificationMessage,
      'groupName': groupName,
      'customLifespan': customLifespan,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'isActive': isActive,
      'notificationId': notificationId,
      if (meetingFrequency != null) 'meetingFrequency': meetingFrequency!.name,
      if (importSource != null) 'importSource': importSource,
      if (importSourceId != null) 'importSourceId': importSourceId,
      if (estimatedYears != null) estimatedYearsKey: estimatedYears,
    };
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      birthDate: decodeBirthDate(map['birthDate']),
      avatarPath: map['avatarPath'],
      notes: map['notes'],
      customNotificationMessage: map['customNotificationMessage'],
      groupName: map['groupName'],
      customLifespan: map['customLifespan']?.toInt() ??
          LifeCalculator.defaultLifeExpectancyYears,
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate']),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
      isActive: map['isActive'] ?? true,
      notificationId: map['notificationId']?.toInt() ?? 0,
      meetingFrequency: MeetingFrequency.tryParse(map['meetingFrequency']),
      hasBirthYear: encodedHasBirthYear(map['birthDate']),
      importSource: map['importSource'] as String?,
      importSourceId: map['importSourceId'] as String?,
      estimatedYears: _intOrNull(map[estimatedYearsKey]),
    );
  }

  /// Date-only `yyyy-MM-dd` form of [date], independent of the time zone;
  /// `--MM-dd` (vCard style) without a year ([hasYear] false).
  static String encodeBirthDate(DateTime date, {bool hasYear = true}) {
    final monthDay = '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    if (!hasYear) return '--$monthDay';
    return '${date.year.toString().padLeft(4, '0')}-$monthDay';
  }

  /// Whether a stored birth date carries a year: false only for `--MM-dd`.
  static bool encodedHasBirthYear(Object? value) =>
      !(value is String && value.startsWith('--'));

  /// Local-midnight birth date from a stored value: a `yyyy-MM-dd` string,
  /// `--MM-dd` (no year, stored in [noYearStorageYear]), or (legacy) epoch
  /// millis of a local-midnight DateTime written in the user's zone, whose
  /// local calendar day is the best available interpretation.
  static DateTime decodeBirthDate(Object? value) {
    final DateTime parsed;
    if (value is String && value.startsWith('--')) {
      parsed = _parseMonthDay(value.substring(2));
    } else if (value is String) {
      parsed = DateTime.parse(value);
    } else if (value is num) {
      parsed = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    } else {
      throw FormatException('Invalid birth date: $value');
    }
    return _dateOnly(parsed);
  }

  static DateTime _parseMonthDay(String monthDay) {
    final match = RegExp(r'^(\d{2})-(\d{2})$').firstMatch(monthDay);
    if (match == null) throw FormatException('Invalid birth date: --$monthDay');
    final month = int.parse(match[1]!);
    final day = int.parse(match[2]!);
    final date = DateTime(noYearStorageYear, month, day);
    if (date.month != month || date.day != day) {
      throw FormatException('Invalid birth date: --$monthDay');
    }
    return date;
  }

  static int? _intOrNull(Object? value) => value is num ? value.toInt() : null;

  String toJson() => json.encode(toMap());

  factory Friend.fromJson(String source) => Friend.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Friend(id: $id, name: $name, birthDate: $birthDate, avatarPath: $avatarPath, notes: $notes, customNotificationMessage: $customNotificationMessage, groupName: $groupName, customLifespan: $customLifespan, createdDate: $createdDate, lastUpdated: $lastUpdated, isActive: $isActive, notificationId: $notificationId, meetingFrequency: $meetingFrequency, hasBirthYear: $hasBirthYear, importSource: $importSource, importSourceId: $importSourceId, estimatedYears: $estimatedYears)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Friend &&
      other.id == id &&
      other.name == name &&
      other.birthDate == birthDate &&
      other.avatarPath == avatarPath &&
      other.notes == notes &&
      other.customNotificationMessage == customNotificationMessage &&
      other.groupName == groupName &&
      other.customLifespan == customLifespan &&
      other.createdDate == createdDate &&
      other.lastUpdated == lastUpdated &&
      other.isActive == isActive &&
      other.notificationId == notificationId &&
      other.meetingFrequency == meetingFrequency &&
      other.hasBirthYear == hasBirthYear &&
      other.importSource == importSource &&
      other.importSourceId == importSourceId &&
      other.estimatedYears == estimatedYears;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      birthDate.hashCode ^
      avatarPath.hashCode ^
      notes.hashCode ^
      customNotificationMessage.hashCode ^
      groupName.hashCode ^
      customLifespan.hashCode ^
      createdDate.hashCode ^
      lastUpdated.hashCode ^
      isActive.hashCode ^
      notificationId.hashCode ^
      meetingFrequency.hashCode ^
      hasBirthYear.hashCode ^
      importSource.hashCode ^
      importSourceId.hashCode ^
      estimatedYears.hashCode;
  }

  /// True when [customLifespan] is the number the estimate applied (not
  /// moved by hand since).
  bool get lifespanFromEstimate => estimatedYears == customLifespan;

  /// Identity that survives a delete + re-import (which assigns a new [id]):
  /// trimmed, lower-case name plus birth date (yyyy-MM-dd, or --MM-dd
  /// without a year).
  String get identityKey =>
      '${name.trim().toLowerCase()}|${encodeBirthDate(birthDate, hasYear: hasBirthYear)}';

  // Birthday and age calculations. These are the canonical rules for
  // friends: a Feb 29 birthday is observed on Feb 28 in non-leap years, and
  // the age changes on that observed birthday.

  /// Birthday date (midnight) in [year]; Feb 29 falls back to Feb 28 in non-leap years.
  DateTime birthdayInYear(int year) => birthdayDateInYear(birthDate, year);

  /// Birthday of someone born on [birthDate] in [year] (Feb 29 -> Feb 28 in non-leap years).
  static DateTime birthdayDateInYear(DateTime birthDate, int year) {
    final isLeapDay = birthDate.month == 2 && birthDate.day == 29;
    if (isLeapDay && !_isLeapYear(year)) {
      return DateTime(year, 2, 28);
    }
    return DateTime(year, birthDate.month, birthDate.day);
  }

  static bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  /// Full years of someone born on [birthDate] on the day of [today]
  /// (never negative).
  static int ageOn(DateTime birthDate, DateTime today) {
    final day = _dateOnly(today);
    final birthdayReached = !day.isBefore(birthdayDateInYear(birthDate, day.year));
    final age = day.year - birthDate.year - (birthdayReached ? 0 : 1);
    return age < 0 ? 0 : age;
  }

  /// Next birthday (midnight) on or after the day of [today].
  static DateTime nextBirthdayOf(DateTime birthDate, DateTime today) {
    final day = _dateOnly(today);
    final thisYear = birthdayDateInYear(birthDate, day.year);
    return thisYear.isBefore(day) ? birthdayDateInYear(birthDate, day.year + 1) : thisYear;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Next birthday (midnight) on or after [today] (default: now).
  DateTime getNextBirthday({DateTime? today}) =>
      nextBirthdayOf(birthDate, today ?? DateTime.now());

  bool isBirthdayToday({DateTime? today}) {
    final day = _dateOnly(today ?? DateTime.now());
    return birthdayInYear(day.year) == day;
  }

  /// Current age in full years; null without a birth year.
  int? getCurrentAge({DateTime? today}) =>
      hasBirthYear ? ageOn(birthDate, today ?? DateTime.now()) : null;

  /// Age turned on the birthday in [year]; null without a birth year.
  int? ageTurningIn(int year) => hasBirthYear ? year - birthDate.year : null;

  /// Whole years left of [customLifespan]; 0 once it is reached, null
  /// without a birth year.
  int? getRemainingYears({DateTime? today}) {
    final age = getCurrentAge(today: today);
    if (age == null) return null;
    final remaining = customLifespan - age;
    return remaining < 0 ? 0 : remaining;
  }

  /// True once [customLifespan] is reached: no years are left to count.
  /// Always false without a birth year.
  bool isBeyondExpectedLifespan({DateTime? today}) {
    final age = getCurrentAge(today: today);
    return age != null && age >= customLifespan;
  }

  int getDaysUntilNextBirthday({DateTime? today}) {
    final day = _dateOnly(today ?? DateTime.now());
    final next = nextBirthdayOf(birthDate, day);
    return DateTime.utc(next.year, next.month, next.day)
        .difference(DateTime.utc(day.year, day.month, day.day))
        .inDays;
  }
}
