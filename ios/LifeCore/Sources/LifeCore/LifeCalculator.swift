/// Swift mirror of lib/core/life_calculator.dart and android/lifecore/.../LifeCalculator.kt.
/// All three are pinned by test/fixtures/life_calculator_vectors.json — keep them in sync.
/// All calculations are date-only.
public struct LifeCalculator: Sendable, Equatable {
    public static let defaultLifeExpectancyYears = 80
    public static let weeksPerYear = 52
    public static let monthsPerYear = 12

    public let birthDate: CivilDate
    public let lifeExpectancyYears: Int
    public let today: CivilDate

    public init(
        birthDate: CivilDate,
        lifeExpectancyYears: Int = LifeCalculator.defaultLifeExpectancyYears,
        today: CivilDate = .today()
    ) {
        self.birthDate = birthDate
        self.lifeExpectancyYears = lifeExpectancyYears
        self.today = today
    }

    private var anniversaryReachedThisYear: Bool {
        today.month > birthDate.month || (today.month == birthDate.month && today.day >= birthDate.day)
    }

    /// Full years of age (a Feb 29 birthday counts from Mar 1 in non-leap years).
    public var ageYears: Int {
        nonNegative(today.year - birthDate.year - (anniversaryReachedThisYear ? 0 : 1))
    }

    public var daysLived: Int { nonNegative(birthDate.days(until: today)) }

    public var weeksLived: Int { daysLived / 7 }

    public var totalWeeks: Int { lifeExpectancyYears * Self.weeksPerYear }

    public var weeksRemaining: Int { nonNegative(totalWeeks - weeksLived) }

    /// 1-based number of the week currently being lived.
    public var currentWeekNumber: Int { weeksLived + 1 }

    /// Completed calendar months since birth.
    public var monthsLived: Int {
        nonNegative(
            (today.year - birthDate.year) * Self.monthsPerYear
                + (today.month - birthDate.month)
                - (today.day < birthDate.day ? 1 : 0)
        )
    }

    public var totalMonths: Int { lifeExpectancyYears * Self.monthsPerYear }

    public var monthsRemaining: Int { nonNegative(totalMonths - monthsLived) }

    public var yearsLived: Int { ageYears }

    public var totalYears: Int { lifeExpectancyYears }

    public var yearsRemaining: Int { nonNegative(totalYears - yearsLived) }

    /// birthDate + lifeExpectancyYears; Feb 29 maps to Mar 1 in non-leap years.
    public var expectedEndDate: CivilDate {
        let year = birthDate.year + lifeExpectancyYears
        return CivilDate(year: year, month: birthDate.month, day: birthDate.day)
            ?? CivilDate(year: year, month: 3, day: 1)!
    }

    public var daysRemaining: Int { nonNegative(today.days(until: expectedEndDate)) }

    /// Share of `totalWeeks` already lived, 0...100 (widgets show the floor).
    public var percentLived: Double {
        guard totalWeeks > 0 else { return 100 }
        return min(max(Double(weeksLived) / Double(totalWeeks) * 100, 0), 100)
    }

    /// Time left in the widget's display mode (weeks, months, years or days).
    public func remaining(_ mode: WidgetInputs.DisplayMode) -> Int {
        switch mode {
        case .weeks: return weeksRemaining
        case .months: return monthsRemaining
        case .years: return yearsRemaining
        case .days: return daysRemaining
        }
    }

    private func nonNegative(_ value: Int) -> Int { value < 0 ? 0 : value }
}
