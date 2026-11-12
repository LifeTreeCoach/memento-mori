import Foundation
import Testing
@testable import LifeCore

/// Runs the shared Dart/Kotlin/Swift vectors from test/fixtures/life_calculator_vectors.json,
/// read in place (repo root = five levels above this file), so the fixture is never duplicated.
struct LifeCalculatorTests {
    struct Vector {
        let name: String
        let calculator: LifeCalculator
        let expected: [String: Double]
    }

    static let fixtureURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // LifeCoreTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // LifeCore
        .deletingLastPathComponent() // ios
        .deletingLastPathComponent() // repo root
        .appendingPathComponent("test/fixtures/life_calculator_vectors.json")

    static func loadVectors() throws -> [Vector] {
        let root = try JSONSerialization.jsonObject(with: Data(contentsOf: fixtureURL)) as? [String: Any]
        let cases = try #require(root?["cases"] as? [[String: Any]])
        return try cases.map { item in
            let name = try #require(item["name"] as? String)
            let birth = try #require((item["birth_date"] as? String).flatMap(CivilDate.init(isoString:)), "\(name)")
            let today = try #require((item["today"] as? String).flatMap(CivilDate.init(isoString:)), "\(name)")
            let years = try #require(item["life_expectancy_years"] as? Int)
            let expected = try #require(item["expected"] as? [String: NSNumber]).mapValues(\.doubleValue)
            return Vector(
                name: name,
                calculator: LifeCalculator(birthDate: birth, lifeExpectancyYears: years, today: today),
                expected: expected
            )
        }
    }

    static func actualValues(_ c: LifeCalculator) -> [String: Double] {
        [
            "age_years": c.ageYears, "days_lived": c.daysLived, "weeks_lived": c.weeksLived,
            "total_weeks": c.totalWeeks, "weeks_remaining": c.weeksRemaining,
            "current_week_number": c.currentWeekNumber, "months_lived": c.monthsLived,
            "total_months": c.totalMonths, "months_remaining": c.monthsRemaining,
            "years_lived": c.yearsLived, "total_years": c.totalYears, "years_remaining": c.yearsRemaining,
            "days_remaining": c.daysRemaining,
        ].mapValues(Double.init).merging(["percent_lived": c.percentLived]) { $1 }
    }

    @Test func matchesSharedFixture() throws {
        let vectors = try Self.loadVectors()
        #expect(vectors.count >= 8)
        for vector in vectors {
            let actual = Self.actualValues(vector.calculator)
            for (key, expected) in vector.expected {
                let value = try #require(actual[key], "\(vector.name): unknown key \(key)")
                #expect(abs(value - expected) < 1e-4, "\(vector.name): \(key) = \(value), expected \(expected)")
            }
        }
    }

    @Test func defaultsToEightyYears() throws {
        let c = LifeCalculator(
            birthDate: try #require(CivilDate(year: 2000, month: 1, day: 1)),
            today: try #require(CivilDate(year: 2000, month: 1, day: 8))
        )
        #expect(c.lifeExpectancyYears == 80)
        #expect(c.currentWeekNumber == 2)
    }

    @Test func futureBirthDateClampsToZero() throws {
        let c = LifeCalculator(
            birthDate: try #require(CivilDate(year: 2030, month: 1, day: 1)),
            today: try #require(CivilDate(year: 2026, month: 1, day: 1))
        )
        #expect(c.weeksLived == 0)
        #expect(c.ageYears == 0)
        #expect(c.monthsLived == 0)
        #expect(c.percentLived == 0)
    }

    @Test func leapDayBirthdayEndsOnMarchFirst() throws {
        let c = LifeCalculator(
            birthDate: try #require(CivilDate(year: 2000, month: 2, day: 29)),
            lifeExpectancyYears: 1,
            today: try #require(CivilDate(year: 2000, month: 2, day: 29))
        )
        #expect(c.expectedEndDate == CivilDate(year: 2001, month: 3, day: 1))
        #expect(c.daysRemaining == 366)
    }

    @Test func remainingFollowsDisplayMode() throws {
        let c = LifeCalculator(
            birthDate: try #require(CivilDate(year: 1990, month: 3, day: 15)),
            today: try #require(CivilDate(year: 2026, month: 11, day: 2))
        )
        #expect(c.remaining(.weeks) == c.weeksRemaining)
        #expect(c.remaining(.months) == c.monthsRemaining)
        #expect(c.remaining(.years) == c.yearsRemaining)
        #expect(c.remaining(.days) == c.daysRemaining)
    }
}

struct CivilDateTests {
    @Test func parsesAndRejects() {
        #expect(CivilDate(isoString: "1990-11-17") == CivilDate(year: 1990, month: 11, day: 17))
        #expect(CivilDate(isoString: "1990-11-17T00:00:00.000") == CivilDate(year: 1990, month: 11, day: 17))
        #expect(CivilDate(isoString: "2021-02-29") == nil)
        #expect(CivilDate(isoString: "") == nil)
        #expect(CivilDate(isoString: "17.11.1990") == nil)
    }

    @Test func epochDayMatchesKnownValues() throws {
        #expect(try #require(CivilDate(year: 1970, month: 1, day: 1)).epochDay == 0)
        #expect(try #require(CivilDate(year: 2000, month: 3, day: 1)).epochDay == 11_017)
        #expect(try #require(CivilDate(year: 1900, month: 1, day: 1)).epochDay == -25_567)
    }

    /// Late evening in Berlin is already the next day in Tokyo: the day comes from the given zone.
    @Test func todayUsesTheLocalCalendarDay() throws {
        let instant = Date(timeIntervalSince1970: 1_793_570_400) // 2026-11-01T22:00:00Z
        #expect(CivilDate.of(instant, in: try #require(TimeZone(identifier: "Europe/Berlin")))
            == CivilDate(year: 2026, month: 11, day: 1))
        #expect(CivilDate.of(instant, in: try #require(TimeZone(identifier: "Asia/Tokyo")))
            == CivilDate(year: 2026, month: 11, day: 2))
    }
}
