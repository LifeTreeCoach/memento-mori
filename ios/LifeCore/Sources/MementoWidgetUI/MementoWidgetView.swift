import LifeCore
import SwiftUI

/// The widget families this view can draw (WidgetKit's `WidgetFamily`, without depending on
/// WidgetKit so the views render in `swift test` on the Mac).
public enum MementoWidgetFamily: String, CaseIterable, Sendable {
    case systemSmall, systemMedium, systemLarge
    case accessoryCircular, accessoryRectangular, accessoryInline

    public var isAccessory: Bool {
        switch self {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return true
        case .systemSmall, .systemMedium, .systemLarge: return false
        }
    }
}

/// Home- and lock-screen widget content, mirroring the Android Glance widget (LifeWidget.kt):
/// quiet stoic look, serif week number, amber "now". Home-screen families expect the palette
/// background behind them (`MementoWidgetView.background(for:systemIsDark:)`) and the
/// system's content margins around them.
@available(iOS 16.0, *)
public struct MementoWidgetView: View {
    let inputs: WidgetInputs
    let today: CivilDate
    let family: MementoWidgetFamily

    @Environment(\.colorScheme) private var colorScheme

    public init(inputs: WidgetInputs, today: CivilDate, family: MementoWidgetFamily) {
        self.inputs = inputs
        self.today = today
        self.family = family
    }

    /// Background colour for the widget container.
    public static func background(for inputs: WidgetInputs, systemIsDark: Bool) -> Color {
        LifePalette.resolve(for: inputs, systemIsDark: systemIsDark).background.color
    }

    public var body: some View {
        let style = WidgetStyle(
            inputs: inputs,
            palette: LifePalette.resolve(for: inputs, systemIsDark: colorScheme == .dark),
            text: WidgetText(language: inputs.language)
        )
        let calc = inputs.calculator(today: today)
        if family.isAccessory {
            AccessoryContent(family: family, style: style, calc: calc)
        } else if let calc {
            HomeContent(family: family, style: style, calc: calc)
        } else {
            SetupContent(style: style)
        }
    }
}

/// Everything a widget layout needs besides the numbers.
struct WidgetStyle {
    let inputs: WidgetInputs
    let palette: LifePalette
    let text: WidgetText
}

private struct HomeContent: View {
    let family: MementoWidgetFamily
    let style: WidgetStyle
    let calc: LifeCalculator

    var body: some View {
        switch family {
        case .systemMedium: medium
        case .systemLarge: large
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetLabel(text: style.text.weekLabel, color: style.palette.secondary)
            BigNumber(text: style.text.number(calc.currentWeekNumber), color: style.palette.primary, size: 34)
            Spacer(minLength: 10)
            LifeProgressBar(calc: calc, palette: style.palette)
            Caption(text: style.text.percent(calc), color: style.palette.secondary)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 8) {
            header(numberSize: 34, showsTotal: false)
            grid(.yearStrip)
            LifeProgressBar(calc: calc, palette: style.palette)
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 10) {
            header(numberSize: 30, showsTotal: true)
            grid(.weeks)
        }
    }

    private func header(numberSize: CGFloat, showsTotal: Bool) -> some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 0) {
                WidgetLabel(text: style.text.weekLabel, color: style.palette.secondary)
                BigNumber(text: style.text.number(calc.currentWeekNumber), color: style.palette.primary, size: numberSize)
                if showsTotal {
                    Caption(text: style.text.ofTotal(calc.totalWeeks), color: style.palette.secondary)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Caption(text: style.text.remaining(calc, mode: style.inputs.displayMode), color: style.palette.primary)
                Caption(text: style.text.percentLived(calc), color: style.palette.secondary)
            }
        }
    }

    private func grid(_ kind: LifeGridView.Kind) -> some View {
        LifeGridView(kind: kind, calc: calc, palette: style.palette, accessibilityText: style.text.gridDescription)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SetupContent: View {
    let style: WidgetStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetLabel(text: style.text.appName, color: style.palette.accent)
            Text(style.text.setupMessage)
                .font(.system(size: 14))
                .foregroundStyle(style.palette.primary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// Thin accent bar on the track colour (the Android widget's LinearProgressIndicator).
struct LifeProgressBar: View {
    let calc: LifeCalculator
    let palette: LifePalette

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(palette.track.color)
                Capsule()
                    .fill(palette.accent.color)
                    .frame(width: proxy.size.width * calc.percentLived / 100)
            }
        }
        .frame(height: 3)
        .accessibilityHidden(true)
    }
}

struct WidgetLabel: View {
    let text: String
    let color: ARGBColor

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .medium))
            .kerning(0.6)
            .foregroundStyle(color.color)
            .lineLimit(1)
    }
}

struct BigNumber: View {
    let text: String
    let color: ARGBColor
    let size: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: size, design: .serif))
            .foregroundStyle(color.color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

struct Caption: View {
    let text: String
    let color: ARGBColor

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(color.color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}
