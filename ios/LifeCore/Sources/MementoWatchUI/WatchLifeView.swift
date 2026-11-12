import LifeCore
import SwiftUI

/// The watch app's only screen, mirroring the Wear OS app (WatchScreen.kt): "WEEK" label, big
/// week number and percent inside an amber progress ring, the time left in the widget's
/// display mode, and one dot per year of life expectancy.
public struct WatchLifeView: View {
    let state: WatchState

    public init(state: WatchState) {
        self.state = state
    }

    public var body: some View {
        Group {
            if let life = state.life {
                ScrollView {
                    WatchLifeContent(state: state, life: life)
                }
            } else {
                WatchNeedsPhoneView(text: state.text, palette: state.palette)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(state.palette.background.color)
    }
}

/// Asks the user to open the iPhone app, which sends the inputs.
public struct WatchNeedsPhoneView: View {
    let text: WidgetText
    let palette: LifePalette

    public init(text: WidgetText, palette: LifePalette = .stoicDark) {
        self.text = text
        self.palette = palette
    }

    public var body: some View {
        Text(text.needsPhone)
            .font(.system(size: 15))
            .foregroundStyle(palette.primary.color)
            .multilineTextAlignment(.center)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Scrollable content of a configured watch (outside the ScrollView so snapshots can render it).
public struct WatchLifeContent: View {
    let state: WatchState
    let life: WatchState.Life

    public init(state: WatchState, life: WatchState.Life) {
        self.state = state
        self.life = life
    }

    public var body: some View {
        VStack(spacing: 8) {
            WeekRing(text: state.text, life: life, palette: state.palette)
            Text(state.remaining(life))
                .font(.system(size: 15))
                .foregroundStyle(state.palette.primary.color)
                .multilineTextAlignment(.center)
            Text(state.text.yearsTitle)
                .font(.system(size: 12))
                .foregroundStyle(state.palette.secondary.color)
                .padding(.top, 4)
            YearsDots(strip: life.years, palette: state.palette)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WeekRing: View {
    let text: WidgetText
    let life: WatchState.Life
    let palette: LifePalette

    var body: some View {
        ZStack {
            Circle()
                .stroke(palette.track.color, lineWidth: 8)
            Circle()
                .trim(from: 0, to: life.progress)
                .stroke(palette.accent.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(text.weekLabel.uppercased())
                    .font(.system(size: 13))
                    .tracking(2)
                    .foregroundStyle(palette.secondary.color)
                Text(text.number(life.weekNumber))
                    .font(.system(size: 40, weight: .bold, design: .serif))
                    .foregroundStyle(palette.primary.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(text.percent(life.calc))
                    .font(.system(size: 16))
                    .foregroundStyle(palette.accent.color)
            }
            .padding(.horizontal, 16)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct YearsDots: View {
    let strip: YearsStrip
    let palette: LifePalette

    var body: some View {
        Canvas { context, size in
            let cell = size.width / CGFloat(YearsStrip.columns)
            let radius = cell * 0.32
            for index in 0..<strip.totalYears {
                let center = CGPoint(
                    x: cell * (CGFloat(index % YearsStrip.columns) + 0.5),
                    y: cell * (CGFloat(index / YearsStrip.columns) + 0.5)
                )
                let dot = Path(ellipseIn: CGRect(
                    x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2
                ))
                context.fill(dot, with: .color(color(strip.dot(index))))
            }
        }
        .aspectRatio(CGFloat(YearsStrip.columns) / CGFloat(max(strip.rows, 1)), contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func color(_ dot: YearsStrip.Dot) -> Color {
        switch dot {
        case .lived: return palette.lived.color
        case .current: return palette.current.color
        case .remaining: return palette.remaining.color
        }
    }
}
