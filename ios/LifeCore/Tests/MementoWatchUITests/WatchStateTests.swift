import LifeCore
import Testing
@testable import MementoWatchUI

/// Must match the Wear OS app (android/wear WatchState.kt, YearsStrip.kt, strings.xml).
struct WatchStateTests {
    // 1990-11-17 → 2026-11-02: week 1,877, 2,284 weeks left, 45.1 % lived (fixture "typical adult").
    static let today = CivilDate(year: 2026, month: 11, day: 2)!

    static func inputs(_ values: [String: Any]) -> WidgetInputs {
        WidgetInputs(values: ["birth_date": "1990-11-17", "language": "en"].merging(values) { $1 })
    }

    @Test func configuredLife() throws {
        let state = WatchState(inputs: Self.inputs([:]), today: Self.today)
        let life = try #require(state.life)
        #expect(life.weekNumber == 1877)
        #expect(life.percentLived == 45)
        #expect(abs(life.progress - 0.4512) < 0.001)
        #expect(state.remaining(life) == "2,284 weeks left")
        #expect(life.years == YearsStrip(yearsLived: 35, totalYears: 80))
    }

    @Test func remainingFollowsDisplayModeAndLanguage() throws {
        let state = WatchState(inputs: Self.inputs(["language": "de", "widget_display_mode": "years"]), today: Self.today)
        let life = try #require(state.life)
        #expect(state.remaining(life) == "noch 45 Jahre")
        #expect(state.text.percent(life.calc) == "45\u{00A0}%")
    }

    @Test func missingBirthDateNeedsPhone() {
        let state = WatchState(inputs: WidgetInputs(values: [:]), today: Self.today)
        #expect(state.life == nil)
        #expect(state.text.needsPhone == "Öffne Memento Mori auf deinem iPhone")
        let english = WatchState(inputs: Self.inputs(["birth_date": ""]), today: Self.today)
        #expect(english.text.needsPhone == "Open Memento Mori on your iPhone")
        #expect(english.text.yearsTitle == "Your life in years")
    }

    @Test func progressIsClampedAfterLifeExpectancy() throws {
        let state = WatchState(inputs: Self.inputs(["birth_date": "1930-01-01"]), today: Self.today)
        #expect(try #require(state.life).progress == 1)
    }

    @Test func paletteFollowsTheThemeStyleInDark() {
        let warm = WatchState(inputs: Self.inputs(["theme_style": "warm", "brightness": "light"]), today: Self.today)
        #expect(warm.palette == .warmDark)
        #expect(WatchState(inputs: WidgetInputs(values: [:]), today: Self.today).palette == .stoicDark)
    }

    @Test func yearsStripDots() {
        let strip = YearsStrip(yearsLived: 35, totalYears: 85)
        #expect(strip.rows == 9)
        #expect(strip.dot(0) == .lived)
        #expect(strip.dot(34) == .lived)
        #expect(strip.dot(35) == .current)
        #expect(strip.dot(36) == .remaining)
    }
}
