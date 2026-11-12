import Foundation

/// A calendar day in the proleptic Gregorian calendar, without time or time zone
/// (the Swift counterpart of Kotlin's `LocalDate` and the Dart calculator's UTC dates).
public struct CivilDate: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    /// Returns nil for impossible dates such as 2021-02-29.
    public init?(year: Int, month: Int, day: Int) {
        guard (1...12).contains(month), (1...CivilDate.daysInMonth(year: year, month: month)).contains(day) else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }

    /// Parses `yyyy-MM-dd` (anything after the first 10 characters is ignored, like on Android).
    public init?(isoString: String) {
        let parts = isoString.trimmingCharacters(in: .whitespaces).prefix(10).split(separator: "-")
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else {
            return nil
        }
        self.init(year: year, month: month, day: day)
    }

    /// The local calendar day of `date`. Always Gregorian (birth dates are stored as Gregorian
    /// `yyyy-MM-dd`), in the given time zone — the user's current one by default.
    public static func of(_ date: Date, in timeZone: TimeZone = .current) -> CivilDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return CivilDate(year: parts.year!, month: parts.month!, day: parts.day!)!
    }

    public static func today(in timeZone: TimeZone = .current) -> CivilDate { of(Date(), in: timeZone) }

    public static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    public static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 2: return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }

    /// Days since 1970-01-01 (Howard Hinnant's days_from_civil); pure integer arithmetic,
    /// so no DST or time-zone effects.
    public var epochDay: Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yearOfEra = y - era * 400
        let dayOfYear = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146_097 + dayOfEra - 719_468
    }

    /// Whole days from `self` to `other` (negative if `other` is earlier).
    public func days(until other: CivilDate) -> Int { other.epochDay - epochDay }

    public static func < (lhs: CivilDate, rhs: CivilDate) -> Bool { lhs.epochDay < rhs.epochDay }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}
