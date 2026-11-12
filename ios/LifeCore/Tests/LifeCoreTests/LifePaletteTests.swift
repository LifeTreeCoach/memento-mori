import Testing
@testable import LifeCore

struct LifePaletteTests {
    func inputs(style: String, brightness: String, lived: UInt32 = 0xFF1F_1E1C) -> WidgetInputs {
        WidgetInputs(values: [
            "theme_style": style, "brightness": brightness,
            "color_lived": Int64(lived), "color_remaining": Int64(0xFF00_FF00),
        ])
    }

    @Test func brightnessOverridesTheSystemScheme() {
        #expect(LifePalette.resolve(for: inputs(style: "stoic", brightness: "light"), systemIsDark: true) == .stoicLight)
        #expect(LifePalette.resolve(for: inputs(style: "warm", brightness: "dark"), systemIsDark: false) == .warmDark)
        #expect(LifePalette.resolve(for: inputs(style: "warm", brightness: "system"), systemIsDark: true) == .warmDark)
        #expect(LifePalette.resolve(for: inputs(style: "stoic", brightness: "system"), systemIsDark: false) == .stoicLight)
    }

    @Test func userColourThemeOverridesOnlyGridCells() {
        let palette = LifePalette.resolve(for: inputs(style: "stoic", brightness: "dark", lived: 0xFF12_3456), systemIsDark: false)
        #expect(palette.lived.argb == 0xFF12_3456)
        #expect(palette.remaining.argb == 0xFF00_FF00)
        #expect(palette.background == LifePalette.stoicDark.background)
        #expect(palette.current == LifePalette.stoicDark.current)
    }

    func userTheme(brightness: String, dark: Bool) -> WidgetInputs {
        var values: [String: Any] = [
            "theme_style": "stoic", "brightness": brightness,
            "color_lived": Int64(0xFF15_65C0), "color_remaining": Int64(0xFFE3_F2FD),
        ]
        if dark {
            values["color_lived_dark"] = Int64(0xFF5A_8FD0)
            values["color_remaining_dark"] = Int64(0xFF1C_2A3A)
        }
        return WidgetInputs(values: values)
    }

    @Test func userColourThemeUsesDarkVariantsInDarkMode() {
        let dark = LifePalette.resolve(for: userTheme(brightness: "system", dark: true), systemIsDark: true)
        #expect(dark.lived.argb == 0xFF5A_8FD0)
        #expect(dark.remaining.argb == 0xFF1C_2A3A)
        let light = LifePalette.resolve(for: userTheme(brightness: "system", dark: true), systemIsDark: false)
        #expect(light.lived.argb == 0xFF15_65C0)
        #expect(light.remaining.argb == 0xFFE3_F2FD)
    }

    @Test func userColourThemeWithoutDarkVariantsKeepsLightColours() {
        let dark = LifePalette.resolve(for: userTheme(brightness: "dark", dark: false), systemIsDark: false)
        #expect(dark.lived.argb == 0xFF15_65C0)
        #expect(dark.remaining.argb == 0xFFE3_F2FD)
    }

    @Test func stylePaletteIgnoresDarkVariants() {
        let inputs = WidgetInputs(values: [
            "theme_style": "warm", "brightness": "dark",
            "color_lived": Int64(0xFFEF_A27F), "color_remaining_dark": Int64(0xFF00_0000),
        ])
        #expect(LifePalette.resolve(for: inputs, systemIsDark: false) == .warmDark)
    }

    @Test func argbComponents() {
        let color = ARGBColor(0x80FF_0000)
        #expect(color.red == 1)
        #expect(color.green == 0)
        #expect(abs(color.alpha - 128.0 / 255) < 1e-9)
    }

    // MARK: Watch palette (mirrors Kotlin LifePaletteWatchTest)

    @Test func watchUsesTheDarkStyleWhateverTheBrightness() {
        #expect(LifePalette.watch(for: WidgetInputs(values: [:])) == .stoicDark)
        #expect(LifePalette.watch(for: inputs(style: "stoic", brightness: "light")) == .stoicDark)
        #expect(LifePalette.watch(for: inputs(style: "warm", brightness: "light", lived: 0xFFEF_A27F)) == .warmDark)
        #expect(LifePalette.watch(for: inputs(style: "warm", brightness: "system", lived: 0xFFEF_A27F)) == .warmDark)
    }

    @Test func watchStylePaletteIgnoresPublishedDarkColours() {
        let values: [String: Any] = ["theme_style": "warm", "color_lived": Int64(0xFFEF_A27F), "color_lived_dark": 1]
        #expect(LifePalette.watch(for: WidgetInputs(values: values)) == .warmDark)
    }

    @Test func watchUserThemeUsesDarkVariantsOnTheStyleBackground() {
        var values: [String: Any] = [
            "theme_style": "warm", "brightness": "light",
            "color_lived": Int64(0xFF15_65C0), "color_remaining": Int64(0xFFE3_F2FD),
            "color_lived_dark": Int64(0xFF5A_8FD0), "color_remaining_dark": Int64(0xFF1C_2A3A),
        ]
        let palette = LifePalette.watch(for: WidgetInputs(values: values))
        #expect(palette.lived.argb == 0xFF5A_8FD0)
        #expect(palette.remaining.argb == 0xFF1C_2A3A)
        #expect(palette.current == LifePalette.warmDark.current)
        #expect(palette.background == LifePalette.warmDark.background)
        #expect(palette.accent == LifePalette.warmDark.accent)
        values["color_accent_dark"] = Int64(0xFFFF_D08A)
        #expect(LifePalette.watch(for: WidgetInputs(values: values)).current.argb == 0xFFFF_D08A)
    }

    @Test func watchUserThemeWithoutDarkVariantsFallsBackToTheStyle() {
        #expect(LifePalette.watch(for: userTheme(brightness: "light", dark: false)) == .stoicDark)
        let values: [String: Any] = ["theme_style": "warm", "color_lived": Int64(0xFF15_65C0)]
        #expect(LifePalette.watch(for: WidgetInputs(values: values)) == .warmDark)
    }
}
