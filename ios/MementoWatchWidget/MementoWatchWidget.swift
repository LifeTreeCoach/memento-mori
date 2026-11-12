import LifeCore
import MementoWatchUI
import MementoWidgetUI
import SwiftUI
import WidgetKit

/// Watch-face complications. Read the inputs the watch app cached from the iPhone in the
/// shared App Group (MementoWatch/WatchInputsStore.swift) and compute everything with LifeCore,
/// so they roll over at midnight without the phone. The watch app reloads them on new inputs.
@main
struct MementoWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        MementoWatchWidget()
    }
}

struct MementoWatchWidget: Widget {
    static let kind = "MementoWatchWidget"

    var body: some WidgetConfiguration {
        let text = WidgetText(language: WidgetInputs.load().language)
        return StaticConfiguration(kind: Self.kind, provider: LifeTimelineProvider()) { entry in
            WatchComplicationEntryView(entry: entry)
        }
        .configurationDisplayName(text.appName)
        .description(text.widgetDescription)
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct WatchComplicationEntryView: View {
    let entry: LifeEntry

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        WatchComplicationView(
            state: WatchState(inputs: entry.inputs, today: CivilDate.of(entry.date)),
            family: WatchComplicationFamily(widgetFamily)
        )
        .containerBackground(for: .widget) { Color.clear }
    }
}

private extension WatchComplicationFamily {
    init(_ family: WidgetFamily) {
        switch family {
        case .accessoryRectangular: self = .accessoryRectangular
        case .accessoryInline: self = .accessoryInline
        case .accessoryCorner: self = .accessoryCorner
        default: self = .accessoryCircular
        }
    }
}
