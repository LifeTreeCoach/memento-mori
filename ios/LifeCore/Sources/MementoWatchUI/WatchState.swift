import LifeCore

/// Everything the watch app and complications show, computed from the phone's inputs with
/// LifeCore. Mirrors the Wear OS app's WatchState.kt.
public struct WatchState: Equatable, Sendable {
    /// The numbers of a configured life; nil until the phone has sent a birth date.
    public struct Life: Equatable, Sendable {
        public let calc: LifeCalculator
        public let displayMode: WidgetInputs.DisplayMode

        public var weekNumber: Int { calc.currentWeekNumber }
        /// Floor of the lived share, as shown everywhere ("45%").
        public var percentLived: Int { Int(calc.percentLived) }
        /// Exact lived share 0...1 for rings and gauges.
        public var progress: Double { min(max(calc.percentLived / 100, 0), 1) }
        public var years: YearsStrip { YearsStrip(yearsLived: calc.yearsLived, totalYears: calc.totalYears) }
    }

    public let text: WidgetText
    public let life: Life?
    /// Colours of the watch app: the dark variant of the phone's theme (`LifePalette.watch(for:)`).
    public let palette: LifePalette

    public init(inputs: WidgetInputs, today: CivilDate = .today()) {
        text = WidgetText(language: inputs.language)
        palette = LifePalette.watch(for: inputs)
        life = inputs.calculator(today: today).map { Life(calc: $0, displayMode: inputs.displayMode) }
    }

    /// "2,284 weeks left" in the display mode chosen for the widget.
    public func remaining(_ life: Life) -> String {
        text.remaining(life.calc, mode: life.displayMode)
    }

    public static func == (lhs: WatchState, rhs: WatchState) -> Bool {
        lhs.text.language == rhs.text.language && lhs.life == rhs.life && lhs.palette == rhs.palette
    }
}

/// One dot per year of life expectancy, laid out in rows of `columns` (Wear OS YearsStrip.kt).
public struct YearsStrip: Equatable, Sendable {
    public enum Dot: Sendable { case lived, current, remaining }

    public static let columns = 10

    public let yearsLived: Int
    public let totalYears: Int

    public var rows: Int { (totalYears + Self.columns - 1) / Self.columns }

    public func dot(_ index: Int) -> Dot {
        if index < yearsLived { return .lived }
        return index == yearsLived ? .current : .remaining
    }
}
