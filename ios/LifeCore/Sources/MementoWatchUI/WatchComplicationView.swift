import LifeCore
import SwiftUI
#if os(watchOS)
import WidgetKit
#endif

/// The complication families this view can draw (WidgetKit's `WidgetFamily` on watchOS,
/// without depending on WidgetKit so the views also render in `swift test` on the Mac).
public enum WatchComplicationFamily: String, CaseIterable, Sendable {
    case accessoryCircular, accessoryRectangular, accessoryInline, accessoryCorner
}

/// Watch-face complications, mirroring the Wear OS complication (ComplicationContent.kt):
/// a gauge of the lived share around the current week number. The watch face tints them,
/// so text uses semantic styles (primary/secondary); only the gauges get the theme's dark
/// accent as `tint`, which full-colour faces show and tinted faces replace.
@available(iOS 16.0, *)
public struct WatchComplicationView: View {
    let state: WatchState
    let family: WatchComplicationFamily

    public init(state: WatchState, family: WatchComplicationFamily) {
        self.state = state
        self.family = family
    }

    public var body: some View {
        if let life = state.life {
            configured(life)
        } else {
            needsPhone
        }
    }

    @ViewBuilder
    private func configured(_ life: WatchState.Life) -> some View {
        let text = state.text
        switch family {
        case .accessoryCircular:
            Gauge(value: life.progress) {
                Text(text.percent(life.calc))
            } currentValueLabel: {
                // Ungrouped so four digits fit ("1912").
                Text(String(life.weekNumber))
                    .minimumScaleFactor(0.5)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(state.palette.accent.color)
            .accessibilityLabel("\(text.weekNumber(life.calc)), \(text.percentLived(life.calc))")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(text.weekNumber(life.calc))
                    .font(.system(.headline, design: .serif))
                Text(state.remaining(life))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ComplicationProgressBar(fraction: life.progress)
                    .padding(.top, 3)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryInline:
            Text("\(text.weekNumber(life.calc)) · \(text.percent(life.calc))")
        case .accessoryCorner:
            Text(text.percent(life.calc))
                .font(.system(size: 14, weight: .semibold))
                .minimumScaleFactor(0.6)
                .cornerLabel {
                    Gauge(value: life.progress) {
                        Text(text.weekLabel)
                    } currentValueLabel: {
                        Text(String(life.weekNumber))
                    } minimumValueLabel: {
                        Text(text.shortWeekNumber(life.weekNumber))
                    } maximumValueLabel: {
                        Text("")
                    }
                    .tint(state.palette.accent.color)
                }
        }
    }

    @ViewBuilder
    private var needsPhone: some View {
        let text = state.text
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(text.appName).font(.headline)
                Text(text.needsPhone).font(.caption).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryInline:
            Text(text.appName)
        case .accessoryCircular, .accessoryCorner:
            Image(systemName: "hourglass")
                .font(.title3)
                .accessibilityLabel(text.needsPhone)
        }
    }
}

private extension View {
    /// The curved label along the bezel of a corner complication (watchOS only; the Mac
    /// snapshots show the centre content).
    @ViewBuilder
    func cornerLabel<Label: View>(@ViewBuilder _ label: () -> Label) -> some View {
        #if os(watchOS)
        widgetLabel { label() }
        #else
        self
        #endif
    }
}

/// Drawn bar instead of ProgressView, which ImageRenderer (snapshots) cannot render.
private struct ComplicationProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.secondary.opacity(0.4))
                Capsule().frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}
