import Foundation

/// Inputs published by the Flutter app via home_widget (docs/widget-data-contract.md),
/// mirroring android/lifecore/.../WidgetInputs.kt. Numbers may arrive as Int, Int64 or
/// NSNumber (and ARGB colours ≥ 0x80000000 as 64-bit values), so they are truncated to 32 bits.
public struct WidgetInputs: Equatable, Sendable {
    public static let appGroup = "group.lifetree.coach.memento_mori_life_in_weeks"
    public static let defaultAccent: UInt32 = 0xFFE0_A84F

    public enum DisplayMode: String, CaseIterable, Sendable { case weeks, months, years, days }
    public enum Language: String, Sendable {
        case de, en, fr, es

        /// Fallback when no (supported) language was published: the device's preferred language
        /// if it is supported (German, French, Spanish), English otherwise (like the app's initial
        /// language). Only the first preferred language counts.
        public static func preferred(_ preferredLanguages: [String] = Locale.preferredLanguages) -> Language {
            guard let first = preferredLanguages.first?.lowercased() else { return .en }
            let code = String(first.prefix { $0 != "-" && $0 != "_" })
            return Language(rawValue: code) ?? .en
        }
    }
    public enum ThemeStyle: String, Sendable { case stoic, warm }
    public enum Brightness: String, Sendable { case system, light, dark }

    public enum State: Equatable, Sendable {
        case configured(CivilDate)
        /// No birth date yet: the widget asks the user to open the app.
        case missingBirthDate
    }

    public var schemaVersion: Int
    public var birthDate: CivilDate?
    public var lifeExpectancyYears: Int
    public var displayMode: DisplayMode
    public var language: Language
    public var themeStyle: ThemeStyle
    public var brightness: Brightness
    /// ARGB.
    public var colorLived: UInt32
    public var colorRemaining: UInt32
    public var colorAccent: UInt32
    /// Dark-mode variants of a user colour theme (optional keys); nil = use the light colour.
    public var colorLivedDark: UInt32?
    public var colorRemainingDark: UInt32?
    public var colorAccentDark: UInt32?

    public var state: State {
        birthDate.map(State.configured) ?? .missingBirthDate
    }

    public func calculator(today: CivilDate = .today()) -> LifeCalculator? {
        birthDate.map { LifeCalculator(birthDate: $0, lifeExpectancyYears: lifeExpectancyYears, today: today) }
    }

    /// Decodes the contract keys from a raw dictionary (UserDefaults or a WatchConnectivity context).
    /// `preferredLanguages` only matters when `language` is missing or unsupported.
    public init(values: [String: Any], preferredLanguages: [String] = Locale.preferredLanguages) {
        schemaVersion = Self.readInt(values["schema_version"]).map(Int.init) ?? 1
        birthDate = (values["birth_date"] as? String).flatMap(CivilDate.init(isoString:))
        lifeExpectancyYears = Self.readInt(values["life_expectancy_years"]).map { Int($0) }
            .flatMap { $0 > 0 ? $0 : nil } ?? LifeCalculator.defaultLifeExpectancyYears
        displayMode = (values["widget_display_mode"] as? String)
            .flatMap { DisplayMode(rawValue: $0.lowercased()) } ?? .weeks
        language = (values["language"] as? String).flatMap(Language.init(rawValue:))
            ?? .preferred(preferredLanguages)
        themeStyle = (values["theme_style"] as? String).flatMap(ThemeStyle.init(rawValue:)) ?? .stoic
        brightness = (values["brightness"] as? String).flatMap(Brightness.init(rawValue:)) ?? .system
        colorLived = Self.readColor(values["color_lived"]) ?? 0xFF00_0000
        colorRemaining = Self.readColor(values["color_remaining"]) ?? 0xFFFF_FFFF
        colorAccent = Self.readColor(values["color_accent"]) ?? Self.defaultAccent
        colorLivedDark = Self.readColor(values["color_lived_dark"])
        colorRemainingDark = Self.readColor(values["color_remaining_dark"])
        colorAccentDark = Self.readColor(values["color_accent_dark"])
    }

    /// Reads the contract keys from `defaults` (normally the App Group suite).
    public init(defaults: UserDefaults) {
        self.init(values: Self.contractValues(in: defaults))
    }

    /// Inputs from the App Group; defaults (not set up) if the suite is unavailable.
    public static func load() -> WidgetInputs {
        WidgetInputs(defaults: UserDefaults(suiteName: appGroup) ?? .standard)
    }

    /// Only the contract keys of `values` (e.g. the App Group, which also holds unrelated keys),
    /// mirroring Kotlin `WidgetInputs.contractValues`. The phone sends this to the watch.
    public static func contractValues(_ values: [String: Any]) -> [String: Any] {
        values.filter { keys.contains($0.key) }
    }

    /// The contract keys stored in `defaults`.
    public static func contractValues(in defaults: UserDefaults) -> [String: Any] {
        var values: [String: Any] = [:]
        for key in keys {
            values[key] = defaults.object(forKey: key)
        }
        return values
    }

    /// Replaces the contract keys in `defaults` with those in `values` (keys missing from
    /// `values` are removed, so the cache always mirrors the last inputs received).
    public static func store(_ values: [String: Any], in defaults: UserDefaults) {
        for key in keys {
            defaults.set(values[key], forKey: key)
        }
    }

    /// These inputs as contract values (property-list types: `Int` and `String`), so
    /// `WidgetInputs(values: inputs.contractValues) == inputs`. An unset birth date is "".
    /// Optional dark colours are only present when set.
    public var contractValues: [String: Any] {
        var values: [String: Any] = [
            "schema_version": schemaVersion,
            "birth_date": birthDate?.description ?? "",
            "life_expectancy_years": lifeExpectancyYears,
            "widget_display_mode": displayMode.rawValue,
            "language": language.rawValue,
            "theme_style": themeStyle.rawValue,
            "brightness": brightness.rawValue,
            "color_lived": Int(colorLived),
            "color_remaining": Int(colorRemaining),
            "color_accent": Int(colorAccent),
        ]
        values["color_lived_dark"] = colorLivedDark.map { Int($0) }
        values["color_remaining_dark"] = colorRemainingDark.map { Int($0) }
        values["color_accent_dark"] = colorAccentDark.map { Int($0) }
        return values
    }

    public static let keys = [
        "schema_version", "birth_date", "life_expectancy_years", "widget_display_mode", "language",
        "theme_style", "brightness", "color_lived", "color_remaining", "color_accent",
        "color_lived_dark", "color_remaining_dark", "color_accent_dark",
    ]

    /// Any integer (Int, Int64, NSNumber) or numeric string, truncated to 32 bits like Kotlin's `toLong().toInt()`.
    private static func readInt(_ value: Any?) -> Int32? {
        switch value {
        case let number as any BinaryInteger: return Int32(truncatingIfNeeded: number)
        case let number as NSNumber: return Int32(truncatingIfNeeded: number.int64Value)
        case let text as String: return Int64(text).map { Int32(truncatingIfNeeded: $0) }
        default: return nil
        }
    }

    private static func readColor(_ value: Any?) -> UInt32? {
        readInt(value).map { UInt32(bitPattern: $0) }
    }
}
