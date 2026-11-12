#if canImport(SwiftUI)
import SwiftUI
#endif

/// A 32-bit ARGB colour as published by the app (`0xAARRGGBB`).
public struct ARGBColor: Hashable, Sendable {
    public let argb: UInt32

    public init(_ argb: UInt32) {
        self.argb = argb
    }

    public var alpha: Double { Double((argb >> 24) & 0xFF) / 255 }
    public var red: Double { Double((argb >> 16) & 0xFF) / 255 }
    public var green: Double { Double((argb >> 8) & 0xFF) / 255 }
    public var blue: Double { Double(argb & 0xFF) / 255 }

    #if canImport(SwiftUI)
    public var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }
    #endif
}

/// Widget colours for the app's theme style and brightness, mirroring the Android widget's
/// WidgetPalette.kt (itself mirroring lib/theme/app_color_schemes.dart and life_palette.dart).
public struct LifePalette: Hashable, Sendable {
    public let background: ARGBColor
    public let primary: ARGBColor
    public let secondary: ARGBColor
    public let track: ARGBColor
    public let accent: ARGBColor
    public let lived: ARGBColor
    public let remaining: ARGBColor
    public let current: ARGBColor

    public static let stoicLight = LifePalette(
        background: ARGBColor(0xFFF4_F1EA), primary: ARGBColor(0xFF1C_1B1A), secondary: ARGBColor(0xFF5E_5A53),
        track: ARGBColor(0xFFE3_DED3), accent: ARGBColor(0xFFD4_973A),
        lived: ARGBColor(0xFF1F_1E1C), remaining: ARGBColor(0xFFE3_DED3), current: ARGBColor(0xFFD4_973A)
    )
    public static let stoicDark = LifePalette(
        background: ARGBColor(0xFF0F_0F10), primary: ARGBColor(0xFFF4_F1EA), secondary: ARGBColor(0xFFA9_A49B),
        track: ARGBColor(0xFF2A_2A2D), accent: ARGBColor(0xFFE0_A84F),
        lived: ARGBColor(0xFFA3_9D92), remaining: ARGBColor(0xFF2A_2A2D), current: ARGBColor(0xFFE0_A84F)
    )
    public static let warmLight = LifePalette(
        background: ARGBColor(0xFFFF_F8F1), primary: ARGBColor(0xFF2B_2420), secondary: ARGBColor(0xFF6B_5B50),
        track: ARGBColor(0xFFF2_D9C6), accent: ARGBColor(0xFFB4_532A),
        lived: ARGBColor(0xFFEF_A27F), remaining: ARGBColor(0xFFF2_D9C6), current: ARGBColor(0xFFB4_532A)
    )
    public static let warmDark = LifePalette(
        background: ARGBColor(0xFF1E_1714), primary: ARGBColor(0xFFF6_E9DF), secondary: ARGBColor(0xFFD2_BFB2),
        track: ARGBColor(0xFF3F_332C), accent: ARGBColor(0xFFFF_B591),
        lived: ARGBColor(0xFFE6_936E), remaining: ARGBColor(0xFF3F_332C), current: ARGBColor(0xFFFF_D08A)
    )

    /// Lived-cell colours the app publishes when no colour theme overrides the style
    /// (life_palette.dart). Any other `color_lived` is a user-chosen colour theme.
    static let styleDefaultLived: Set<UInt32> = [0xFF1F_1E1C, 0xFFA3_9D92, 0xFFEF_A27F, 0xFFE6_936E]

    /// Palette for `inputs`. `systemIsDark` is the environment's colour scheme and is used only
    /// when the brightness setting is "system" (pass `colorScheme == .dark` from SwiftUI).
    public static func resolve(for inputs: WidgetInputs, systemIsDark: Bool) -> LifePalette {
        let isDark: Bool
        switch inputs.brightness {
        case .light: isDark = false
        case .dark: isDark = true
        case .system: isDark = systemIsDark
        }
        let base: LifePalette
        switch inputs.themeStyle {
        case .stoic: base = isDark ? .stoicDark : .stoicLight
        case .warm: base = isDark ? .warmDark : .warmLight
        }
        guard !styleDefaultLived.contains(inputs.colorLived) else { return base }
        return base.withGrid(lived: ARGBColor(userLived(inputs, isDark)), remaining: ARGBColor(userRemaining(inputs, isDark)))
    }

    /// Palette for the watches, which are dark-first (OLED): always the dark variant of the
    /// selected style, whatever `brightness` says. A user colour theme only replaces the lived /
    /// remaining / current colours with its dark-adapted `*_dark` variants; without them the
    /// style's dark palette is used (light theme colours are not meant for a black screen).
    /// Mirrors Kotlin `LifePalette.watchTones`.
    public static func watch(for inputs: WidgetInputs) -> LifePalette {
        let dark: LifePalette = inputs.themeStyle == .warm ? .warmDark : .stoicDark
        guard !styleDefaultLived.contains(inputs.colorLived), let lived = inputs.colorLivedDark else { return dark }
        return LifePalette(
            background: dark.background, primary: dark.primary, secondary: dark.secondary,
            track: dark.track, accent: dark.accent,
            lived: ARGBColor(lived),
            remaining: inputs.colorRemainingDark.map(ARGBColor.init) ?? dark.remaining,
            current: inputs.colorAccentDark.map(ARGBColor.init) ?? dark.current
        )
    }

    /// A user colour theme's lived colour; in dark mode the app's dark-adapted variant if published.
    private static func userLived(_ inputs: WidgetInputs, _ isDark: Bool) -> UInt32 {
        isDark ? inputs.colorLivedDark ?? inputs.colorLived : inputs.colorLived
    }

    private static func userRemaining(_ inputs: WidgetInputs, _ isDark: Bool) -> UInt32 {
        isDark ? inputs.colorRemainingDark ?? inputs.colorRemaining : inputs.colorRemaining
    }

    private func withGrid(lived: ARGBColor, remaining: ARGBColor) -> LifePalette {
        LifePalette(
            background: background, primary: primary, secondary: secondary, track: track, accent: accent,
            lived: lived, remaining: remaining, current: current
        )
    }
}
