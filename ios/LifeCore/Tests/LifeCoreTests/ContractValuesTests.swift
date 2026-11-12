import Foundation
import Testing
@testable import LifeCore

/// The dictionary the iPhone sends to the watch via WatchConnectivity (docs/widget-data-contract.md).
struct ContractValuesTests {
    static var allKeys: [String: Any] {
        [
            "schema_version": 1, "birth_date": "1990-03-15", "life_expectancy_years": 90,
            "widget_display_mode": "days", "language": "en", "theme_style": "warm", "brightness": "dark",
            "color_lived": Int64(0xFFEF_A27F), "color_remaining": 0xFFF2_D9C6, "color_accent": 0xFFE0_A84F,
            "color_lived_dark": 0xFF5A_8FD0, "color_remaining_dark": 0xFF1C_2A3A, "color_accent_dark": 0xFFFF_D08A,
        ]
    }

    @Test func encodedInputsDecodeToTheSameInputs() {
        let inputs = WidgetInputs(values: Self.allKeys)
        #expect(WidgetInputs(values: inputs.contractValues) == inputs)
        #expect(Set(inputs.contractValues.keys) == Set(WidgetInputs.keys))
    }

    @Test func missingDarkColoursAreNotEncoded() {
        let values = WidgetInputs(values: [:]).contractValues
        #expect(values["color_lived_dark"] == nil)
        #expect(values["color_remaining_dark"] == nil)
        #expect(values["color_accent_dark"] == nil)
    }

    @Test func unsetBirthDateEncodesAsEmptyString() {
        let inputs = WidgetInputs(values: [:])
        #expect(inputs.contractValues["birth_date"] as? String == "")
        #expect(WidgetInputs(values: inputs.contractValues) == inputs)
    }

    @Test func encodedValuesArePropertyListTypes() throws {
        let values = WidgetInputs(values: Self.allKeys).contractValues
        #expect(PropertyListSerialization.propertyList(values, isValidFor: .binary))
    }

    @Test func contractValuesKeepOnlyContractKeys() {
        let values = WidgetInputs.contractValues(["birth_date": "1990-03-15", "flutter.unrelated": true])
        #expect(values.keys.sorted() == ["birth_date"])
    }

    @Test func storeRoundTripsThroughUserDefaults() throws {
        let suite = "ContractValuesTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        var context = Self.allKeys
        context["updated_at"] = Int64(1_762_000_000_000)
        WidgetInputs.store(context, in: defaults)
        #expect(WidgetInputs(defaults: defaults) == WidgetInputs(values: Self.allKeys))
        #expect(defaults.object(forKey: "updated_at") == nil)

        // A later context without a birth date clears the cached one.
        WidgetInputs.store(["language": "de"], in: defaults)
        #expect(WidgetInputs(defaults: defaults).state == .missingBirthDate)
        #expect(WidgetInputs.contractValues(in: defaults).keys.sorted() == ["language"])
    }
}
