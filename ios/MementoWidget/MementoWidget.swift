import LifeCore
import MementoWidgetUI
import SwiftUI
import WidgetKit

/// Home- and lock-screen widget. Reads the inputs the Flutter app publishes to the App Group
/// (docs/widget-data-contract.md) and computes everything with LifeCore, so it stays correct
/// at midnight without the app running. `HomeWidget.updateWidget(iOSName: 'MementoWidget')`
/// reloads it after the inputs change.
@main
struct MementoWidgetBundle: WidgetBundle {
    var body: some Widget {
        MementoWidget()
    }
}

struct MementoWidget: Widget {
    static let kind = "MementoWidget"

    var body: some WidgetConfiguration {
        let text = WidgetText(language: WidgetInputs.load().language)
        return StaticConfiguration(kind: Self.kind, provider: LifeTimelineProvider()) { entry in
            MementoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(text.appName)
        .description(text.widgetDescription)
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline,
        ])
    }
}

struct MementoWidgetEntryView: View {
    let entry: LifeEntry

    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.colorScheme) private var colorScheme

    /// home_widget only reports URLs with a `homeWidget` query item to Flutter, which then
    /// shows the Life tab (same URL as the Android widget's launch intent).
    private static let openAppURL = URL(string: "mementomori://widget?homeWidget")

    var body: some View {
        let family = MementoWidgetFamily(widgetFamily)
        MementoWidgetView(inputs: entry.inputs, today: CivilDate.of(entry.date), family: family)
            .containerBackground(for: .widget) {
                if family.isAccessory {
                    Color.clear
                } else {
                    MementoWidgetView.background(for: entry.inputs, systemIsDark: colorScheme == .dark)
                }
            }
            .widgetURL(Self.openAppURL)
    }
}

private extension MementoWidgetFamily {
    init(_ family: WidgetFamily) {
        switch family {
        case .systemMedium: self = .systemMedium
        case .systemLarge, .systemExtraLarge: self = .systemLarge
        case .accessoryCircular: self = .accessoryCircular
        case .accessoryRectangular: self = .accessoryRectangular
        case .accessoryInline: self = .accessoryInline
        default: self = .systemSmall
        }
    }
}
