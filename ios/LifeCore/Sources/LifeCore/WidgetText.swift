import Foundation

/// Widget texts in the language chosen in the app (not necessarily the system language).
/// Mirrors android/app/src/main/res/values*/strings.xml and WidgetStrings.kt so iOS and
/// watch texts match Android exactly. Labels are returned in sentence case; the views
/// upper-case them (e.g. "WEEK") like the Android widget does.
public struct WidgetText: Sendable {
    public let language: WidgetInputs.Language

    public init(language: WidgetInputs.Language) {
        self.language = language
    }

    private var table: WidgetTextTable { .table(for: language) }

    public var locale: Locale { Locale(identifier: language.rawValue) }

    /// Grouped integer: "1,912" (en) / "1.912" (de) / "1 912" (fr), as the locale groups it.
    public func number(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic).locale(locale))
    }

    public var appName: String { "Memento Mori" }

    /// Widget gallery description (`widget_description`).
    public var widgetDescription: String { table.widgetDescription }

    public var weekLabel: String { table.weekLabel }

    public var setupMessage: String { table.setupMessage }

    /// Watch without inputs from the phone yet.
    public var needsPhone: String { table.needsPhone }

    /// Title above the watch's dots strip (one dot per year).
    public var yearsTitle: String { table.yearsTitle }

    public var gridDescription: String { table.gridDescription }

    /// One-letter week abbreviation for tight complications: "W" (en/de), "S" (fr/es).
    public var weekPrefix: String { table.weekPrefix }

    /// Compact, ungrouped week number for tight complications: "W1912" / "S1912".
    public func shortWeekNumber(_ weekNumber: Int) -> String {
        "\(weekPrefix)\(weekNumber)"
    }

    public func weekNumber(_ calc: LifeCalculator) -> String {
        "\(weekLabel) \(number(calc.currentWeekNumber))"
    }

    public func ofTotal(_ total: Int) -> String {
        "\(table.ofWord) \(number(total))"
    }

    /// Floor of the lived share: "40%" (en) / "40 %" with a no-break space (de, fr, es).
    public func percent(_ calc: LifeCalculator) -> String {
        let value = Int(calc.percentLived)
        return table.spacedPercent ? "\(value)\u{00A0}%" : "\(value)%"
    }

    public func percentLived(_ calc: LifeCalculator) -> String {
        "\(percent(calc)) \(table.livedWord)"
    }

    public func remaining(_ calc: LifeCalculator, mode: WidgetInputs.DisplayMode) -> String {
        let count = calc.remaining(mode)
        let forms = table.units[mode] ?? ("", "")
        let template = table.usesSingular(count) ? table.remainingOne : table.remainingOther
        let unit = table.usesSingular(count) ? forms.one : forms.other
        return template
            .replacingOccurrences(of: "{count}", with: number(count))
            .replacingOccurrences(of: "{unit}", with: unit)
    }
}

/// One language's widget/watch texts (Android: values{,-de,-fr,-es}/strings.xml).
/// Informal address (du / tu / tú) everywhere.
struct WidgetTextTable: Sendable {
    let widgetDescription: String
    let weekLabel: String
    let setupMessage: String
    let needsPhone: String
    let yearsTitle: String
    let gridDescription: String
    let weekPrefix: String
    let ofWord: String
    let livedWord: String
    /// "45 %" with a no-break space instead of "45%".
    let spacedPercent: Bool
    /// "{count} {unit} left" style templates for the singular and plural forms.
    let remainingOne: String
    let remainingOther: String
    let units: [WidgetInputs.DisplayMode: (one: String, other: String)]
    /// CLDR "one": only 1 in English/German/Spanish, 0 and 1 in French (like Android ICU).
    let usesSingular: @Sendable (Int) -> Bool

    static func table(for language: WidgetInputs.Language) -> WidgetTextTable {
        switch language {
        case .en: return english
        case .de: return german
        case .fr: return french
        case .es: return spanish
        }
    }

    private static let english = WidgetTextTable(
        widgetDescription: "Your life in weeks: the current week and the time you have left",
        weekLabel: "Week",
        setupMessage: "Open the app to set your birth date",
        needsPhone: "Open Memento Mori on your iPhone",
        yearsTitle: "Your life in years",
        gridDescription: "Your life in weeks",
        weekPrefix: "W",
        ofWord: "of",
        livedWord: "lived",
        spacedPercent: false,
        remainingOne: "{count} {unit} left",
        remainingOther: "{count} {unit} left",
        units: [.weeks: ("week", "weeks"), .months: ("month", "months"), .years: ("year", "years"), .days: ("day", "days")],
        usesSingular: { $0 == 1 }
    )

    private static let german = WidgetTextTable(
        widgetDescription: "Dein Leben in Wochen: die aktuelle Woche und die verbleibende Zeit",
        weekLabel: "Woche",
        setupMessage: "Öffne die App und gib dein Geburtsdatum ein",
        needsPhone: "Öffne Memento Mori auf deinem iPhone",
        yearsTitle: "Dein Leben in Jahren",
        gridDescription: "Dein Leben in Wochen",
        weekPrefix: "W",
        ofWord: "von",
        livedWord: "gelebt",
        spacedPercent: true,
        remainingOne: "noch {count} {unit}",
        remainingOther: "noch {count} {unit}",
        units: [.weeks: ("Woche", "Wochen"), .months: ("Monat", "Monate"), .years: ("Jahr", "Jahre"), .days: ("Tag", "Tage")],
        usesSingular: { $0 == 1 }
    )

    private static let french = WidgetTextTable(
        widgetDescription: "Ta vie en semaines\u{00A0}: la semaine en cours et le temps qu’il te reste",
        weekLabel: "Semaine",
        setupMessage: "Ouvre l’app pour saisir ta date de naissance",
        needsPhone: "Ouvre Memento Mori sur ton iPhone",
        yearsTitle: "Ta vie en années",
        gridDescription: "Ta vie en semaines",
        weekPrefix: "S",
        ofWord: "sur",
        livedWord: "vécu",
        spacedPercent: true,
        remainingOne: "encore {count} {unit}",
        remainingOther: "encore {count} {unit}",
        units: [.weeks: ("semaine", "semaines"), .months: ("mois", "mois"), .years: ("an", "ans"), .days: ("jour", "jours")],
        usesSingular: { $0 == 0 || $0 == 1 }
    )

    private static let spanish = WidgetTextTable(
        widgetDescription: "Tu vida en semanas: la semana actual y el tiempo que te queda",
        weekLabel: "Semana",
        setupMessage: "Abre la app para introducir tu fecha de nacimiento",
        needsPhone: "Abre Memento Mori en tu iPhone",
        yearsTitle: "Tu vida en años",
        gridDescription: "Tu vida en semanas",
        weekPrefix: "S",
        ofWord: "de",
        livedWord: "vivido",
        spacedPercent: true,
        remainingOne: "queda {count} {unit}",
        remainingOther: "quedan {count} {unit}",
        units: [.weeks: ("semana", "semanas"), .months: ("mes", "meses"), .years: ("año", "años"), .days: ("día", "días")],
        usesSingular: { $0 == 1 }
    )
}
