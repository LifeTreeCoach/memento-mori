import Foundation
import LifeCore
import WidgetKit

/// One widget redraw: the inputs to show and the day they are shown for.
public struct LifeEntry: TimelineEntry, Sendable {
    public let date: Date
    public let inputs: WidgetInputs

    public init(date: Date, inputs: WidgetInputs) {
        self.date = date
        self.inputs = inputs
    }
}

/// Timeline of the iPhone widget and the watch complications: both read the contract keys
/// from their App Group and redraw now and at each of the next local midnights
/// (`WidgetTimeline`), so the week advances without app wake-ups.
public struct LifeTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> LifeEntry {
        LifeEntry(date: .now, inputs: Self.sampleInputs(language: WidgetInputs.load().language))
    }

    /// The widget gallery / watch-face editor shows a sample life until a birth date is set.
    public func getSnapshot(in context: Context, completion: @escaping (LifeEntry) -> Void) {
        let inputs = WidgetInputs.load()
        let showsSample = context.isPreview && inputs.state == .missingBirthDate
        completion(LifeEntry(date: .now, inputs: showsSample ? Self.sampleInputs(language: inputs.language) : inputs))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LifeEntry>) -> Void) {
        let inputs = WidgetInputs.load()
        let entries = WidgetTimeline.entryDates(from: .now).map { LifeEntry(date: $0, inputs: inputs) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    static func sampleInputs(language: WidgetInputs.Language) -> WidgetInputs {
        WidgetInputs(values: ["birth_date": "1990-03-15", "language": language.rawValue])
    }
}
