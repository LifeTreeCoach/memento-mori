import LifeCore
import SwiftUI

/// Lock-screen (accessory) families. The system tints these, so they use semantic
/// styles (primary/secondary) instead of the palette.
@available(iOS 16.0, *)
struct AccessoryContent: View {
    let family: MementoWidgetFamily
    let style: WidgetStyle
    let calc: LifeCalculator?

    var body: some View {
        if let calc {
            configured(calc)
        } else {
            setup
        }
    }

    @ViewBuilder
    private func configured(_ calc: LifeCalculator) -> some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: calc.percentLived, in: 0...100) {
                Text(style.text.weekLabel)
            } currentValueLabel: {
                Text(style.text.percent(calc))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(style.text.weekNumber(calc))
                    .font(.system(.headline, design: .serif))
                Text(style.text.remaining(calc, mode: style.inputs.displayMode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                AccessoryProgressBar(fraction: calc.percentLived / 100)
                    .padding(.top, 3)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            Text("\(style.text.weekNumber(calc)) · \(style.text.percent(calc))")
        }
    }

    @ViewBuilder
    private var setup: some View {
        switch family {
        case .accessoryCircular:
            Image(systemName: "hourglass")
                .font(.title2)
                .accessibilityLabel(style.text.setupMessage)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(style.text.appName).font(.headline)
                Text(style.text.setupMessage).font(.caption).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            Text(style.text.appName)
        }
    }
}

/// Drawn bar instead of ProgressView, which ImageRenderer (snapshots) cannot render.
private struct AccessoryProgressBar: View {
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
