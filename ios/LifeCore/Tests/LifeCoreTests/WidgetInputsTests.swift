import Foundation
import Testing
@testable import LifeCore

struct WidgetInputsTests {
    @Test func decodesAllContractKeys() {
        let inputs = WidgetInputs(values: [
            "schema_version": 1,
            "birth_date": "1990-11-17",
            "life_expectancy_years": Int64(90),
            "widget_display_mode": "months",
            "language": "en",
            "theme_style": "warm",
            "brightness": "dark",
            "color_lived": Int64(0xFF11_2233),
            "color_remaining": NSNumber(value: 0x00FF_FFFF),
            "color_accent": "4278190335",
        ])
        #expect(inputs.state == .configured(CivilDate(year: 1990, month: 11, day: 17)!))
        #expect(inputs.lifeExpectancyYears == 90)
        #expect(inputs.displayMode == .months)
        #expect(inputs.language == .en)
        #expect(inputs.themeStyle == .warm)
        #expect(inputs.brightness == .dark)
        #expect(inputs.colorLived == 0xFF11_2233)
        #expect(inputs.colorRemaining == 0x00FF_FFFF)
        #expect(inputs.colorAccent == 0xFF00_00FF)
    }

    /// home_widget may store a negative 32-bit Int for ARGB values on some paths.
    @Test func acceptsSignedThirtyTwoBitColours() {
        let inputs = WidgetInputs(values: ["color_lived": Int32(bitPattern: 0xFFE0_A84F)])
        #expect(inputs.colorLived == 0xFFE0_A84F)
    }

    @Test func missingValuesFallBackToDefaults() {
        let inputs = WidgetInputs(
            values: ["birth_date": "", "life_expectancy_years": 0, "language": "it"],
            preferredLanguages: ["de-DE", "en-US"]
        )
        #expect(inputs.state == .missingBirthDate)
        #expect(inputs.calculator() == nil)
        #expect(inputs.schemaVersion == 1)
        #expect(inputs.lifeExpectancyYears == 80)
        #expect(inputs.displayMode == .weeks)
        #expect(inputs.language == .de)
        #expect(inputs.themeStyle == .stoic)
        #expect(inputs.brightness == .system)
        #expect(inputs.colorAccent == WidgetInputs.defaultAccent)
    }

    @Test func missingLanguageFollowsDevice() {
        #expect(WidgetInputs(values: [:], preferredLanguages: ["de-AT"]).language == .de)
        #expect(WidgetInputs(values: [:], preferredLanguages: ["it-IT", "de-DE"]).language == .en)
        #expect(WidgetInputs(values: [:], preferredLanguages: ["fr-FR", "de-DE"]).language == .fr)
        #expect(WidgetInputs(values: [:], preferredLanguages: ["es-419"]).language == .es)
        #expect(WidgetInputs(values: [:], preferredLanguages: ["fr_CA"]).language == .fr)
        #expect(WidgetInputs(values: ["language": "fr"], preferredLanguages: ["de-DE"]).language == .fr)
        #expect(WidgetInputs(values: ["language": "es"], preferredLanguages: ["en-US"]).language == .es)
        #expect(WidgetInputs(values: ["language": "it"], preferredLanguages: ["es-ES"]).language == .es)
        #expect(WidgetInputs(values: [:], preferredLanguages: []).language == .en)
        #expect(WidgetInputs(values: ["language": "de"], preferredLanguages: ["en-US"]).language == .de)
    }

    @Test func readsFromUserDefaultsSuite() throws {
        let suite = "LifeCoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("1990-11-17", forKey: "birth_date")
        defaults.set(NSNumber(value: Int64(0xFF11_2233)), forKey: "color_lived")
        defaults.set(Int64(75), forKey: "life_expectancy_years")
        defaults.set("days", forKey: "widget_display_mode")

        let inputs = WidgetInputs(defaults: defaults)
        #expect(inputs.birthDate == CivilDate(year: 1990, month: 11, day: 17))
        #expect(inputs.colorLived == 0xFF11_2233)
        #expect(inputs.lifeExpectancyYears == 75)
        #expect(inputs.displayMode == .days)
    }
}
