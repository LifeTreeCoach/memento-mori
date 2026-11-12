/// Parses the birthday notations found in contacts and vCard files into a
/// date-only [BirthdayDate] (no time zone shifting).
library;

/// Year Apple (and some Android exports) store for "no year".
const int noYearMarker = 1604;

/// Earliest birth year accepted; older years are data errors.
const int earliestBirthYear = 1850;

/// A calendar birthday; [year] is null when the source omits it.
class BirthdayDate {
  const BirthdayDate({required this.month, required this.day, this.year});

  final int month;
  final int day;
  final int? year;

  bool get hasYear => year != null;

  @override
  bool operator ==(Object other) =>
      other is BirthdayDate &&
      other.month == month &&
      other.day == day &&
      other.year == year;

  @override
  int get hashCode => Object.hash(month, day, year);

  @override
  String toString() => 'BirthdayDate(${year ?? '----'}-$month-$day)';
}

final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[T ].*)?$');
final RegExp _basicDate = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T.*)?$');
final RegExp _noYearDate = RegExp(r'^--(\d{2})-?(\d{2})$');
final RegExp _dottedDate = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})?$');
final RegExp _timestamp = RegExp(r'^-?\d{9,16}$');

/// Parses [text] (`yyyy-MM-dd`, `--MM-dd`, `yyyyMMdd`, `--MMdd`, ISO with a
/// time, millisecond timestamps, `dd.MM.yyyy`, `d.M.yyyy`, `d.M.`) or
/// returns null when it is not a real birthday. A year equal to [omitYear]
/// (vCard `X-APPLE-OMIT-YEAR`) or to [noYearMarker] means "no year".
BirthdayDate? parseBirthdayText(
  String? text, {
  int? omitYear,
  DateTime? today,
}) {
  final value = text?.trim() ?? '';
  final parts = _dateParts(value);
  if (parts == null) return null;
  final year = parts.year == omitYear ? null : parts.year;
  return birthdayFromParts(
    year: year,
    month: parts.month,
    day: parts.day,
    today: today,
  );
}

/// Validates separate date fields (as contact APIs return them): a real
/// calendar day (29 February only in leap years or without a year), a year
/// from [earliestBirthYear] on and no date after [today]. [noYearMarker] as
/// year counts as "no year".
BirthdayDate? birthdayFromParts({
  int? year,
  required int month,
  required int day,
  DateTime? today,
}) {
  final effectiveYear = year == noYearMarker ? null : year;
  if (!_isRealDay(effectiveYear, month, day)) return null;
  if (effectiveYear != null &&
      !_isPlausibleBirth(effectiveYear, month, day, today ?? DateTime.now())) {
    return null;
  }
  return BirthdayDate(month: month, day: day, year: effectiveYear);
}

({int? year, int month, int day})? _dateParts(String value) {
  final match =
      _isoDate.firstMatch(value) ??
      _basicDate.firstMatch(value) ??
      _noYearDate.firstMatch(value);
  if (match != null) return _partsFromMatch(match);
  final dotted = _dottedDate.firstMatch(value);
  if (dotted != null) {
    return (
      year: _optionalInt(dotted.group(3)),
      month: int.parse(dotted.group(2)!),
      day: int.parse(dotted.group(1)!),
    );
  }
  if (_timestamp.hasMatch(value)) return _timestampParts(int.parse(value));
  return null;
}

/// Year/month/day groups of the ISO, basic and `--` patterns (the `--`
/// pattern has no year group).
({int? year, int month, int day}) _partsFromMatch(RegExpMatch match) {
  if (match.groupCount == 2) {
    return (
      year: null,
      month: int.parse(match.group(1)!),
      day: int.parse(match.group(2)!),
    );
  }
  return (
    year: int.parse(match.group(1)!),
    month: int.parse(match.group(2)!),
    day: int.parse(match.group(3)!),
  );
}

/// The UTC calendar date of a millisecond timestamp (contact providers store
/// birthdays as midnight UTC).
({int? year, int month, int day})? _timestampParts(int millis) {
  const maxMillis = 8640000000000000;
  if (millis.abs() > maxMillis) return null;
  final date = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  return (year: date.year, month: date.month, day: date.day);
}

int? _optionalInt(String? digits) => digits == null ? null : int.parse(digits);

bool _isRealDay(int? year, int month, int day) {
  if (month < 1 || month > 12 || day < 1) return false;
  return day <= _daysInMonth(year ?? 2000, month);
}

int _daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

bool _isPlausibleBirth(int year, int month, int day, DateTime today) {
  if (year < earliestBirthYear) return false;
  final todayDate = DateTime.utc(today.year, today.month, today.day);
  return !DateTime.utc(year, month, day).isAfter(todayDate);
}
