import Foundation
import ImageIO
import LifeCore
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import MementoWatchUI

/// Renders the watch app and every complication family to PNG for visual review (not compared
/// against references). Output: $WIDGET_SNAPSHOT_DIR, else <tmp>/MementoWidgetSnapshots, as watch_<name>.png.
@MainActor
struct WatchSnapshotTests {
    static let today = CivilDate(year: 2026, month: 11, day: 2)!
    /// Apple Watch Series 11 46 mm screen in points.
    static let screen = CGSize(width: 208, height: 248)

    static func state(
        language: String = "en", birthDate: String = "1990-03-15", mode: String = "weeks", style: String = "stoic",
        extra: [String: Any] = [:]
    ) -> WatchState {
        let values: [String: Any] = ["birth_date": birthDate, "language": language, "widget_display_mode": mode, "theme_style": style]
        return WatchState(inputs: WidgetInputs(values: values.merging(extra) { _, new in new }), today: today)
    }

    /// A user colour theme (Ocean) with the app's dark-adapted variants.
    static let oceanTheme: [String: Any] = [
        "color_lived": Int64(0xFF15_65C0), "color_remaining": Int64(0xFFE3_F2FD),
        "color_lived_dark": Int64(0xFF5A_8FD0), "color_remaining_dark": Int64(0xFF1C_2A3A),
    ]

    static func size(of family: WatchComplicationFamily) -> CGSize {
        switch family {
        case .accessoryCircular: return CGSize(width: 50, height: 50)
        case .accessoryRectangular: return CGSize(width: 178, height: 60)
        case .accessoryInline: return CGSize(width: 178, height: 20)
        case .accessoryCorner: return CGSize(width: 42, height: 42)
        }
    }

    static var outputDirectory: URL {
        if let path = ProcessInfo.processInfo.environment["WIDGET_SNAPSHOT_DIR"] {
            return URL(fileURLWithPath: path)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("MementoWidgetSnapshots")
    }

    @Test func appScreenEnglish() throws {
        try renderScreen(Self.state(), name: "app_en")
    }

    @Test func appScreenGermanYears() throws {
        try renderScreen(Self.state(language: "de", mode: "years"), name: "app_de_years")
    }

    @Test(arguments: ["fr", "es"])
    func appScreenTranslated(language: String) throws {
        try renderScreen(Self.state(language: language, birthDate: "1990-11-17"), name: "app_\(language)")
        try renderFull(Self.state(language: language, birthDate: "1990-11-17", mode: "days"), name: "app_\(language)_days_full")
        try renderScreen(Self.state(language: language, birthDate: ""), name: "app_needs_phone_\(language)")
    }

    @Test func appScreenWarm() throws {
        try renderScreen(Self.state(style: "warm", extra: ["brightness": "light"]), name: "app_warm")
    }

    @Test(arguments: [("en_full", "stoic"), ("warm_full", "warm")])
    func appScrolledContent(name: String, style: String) throws {
        try renderFull(Self.state(style: style), name: "app_\(name)")
    }

    @Test func appScrolledContentUserTheme() throws {
        try renderFull(Self.state(extra: Self.oceanTheme), name: "app_ocean_full")
    }

    @Test func appNeedsPhoneWarm() throws {
        try renderScreen(Self.state(birthDate: "", style: "warm"), name: "app_needs_phone_warm")
    }

    @Test(arguments: [WatchComplicationFamily.accessoryCircular, .accessoryCorner])
    func complicationWarm(family: WatchComplicationFamily) throws {
        try renderComplication(family, Self.state(style: "warm"), name: "\(family.rawValue)_warm")
    }

    private func renderFull(_ state: WatchState, name: String) throws {
        let life = try #require(state.life)
        let content = WatchLifeContent(state: state, life: life)
            .frame(width: Self.screen.width)
            .background(state.palette.background.color)
        try render(content, name: name)
    }

    @Test func appNeedsPhone() throws {
        try renderScreen(Self.state(language: "en", birthDate: ""), name: "app_needs_phone")
    }

    @Test(arguments: WatchComplicationFamily.allCases)
    func complicationEnglish(family: WatchComplicationFamily) throws {
        try renderComplication(family, Self.state(), name: "\(family.rawValue)_en")
    }

    @Test(arguments: WatchComplicationFamily.allCases)
    func complicationGerman(family: WatchComplicationFamily) throws {
        try renderComplication(family, Self.state(language: "de", mode: "months"), name: "\(family.rawValue)_de")
    }

    @Test(arguments: WatchComplicationFamily.allCases, ["fr", "es"])
    func complicationTranslated(family: WatchComplicationFamily, language: String) throws {
        let state = Self.state(language: language, birthDate: "1990-11-17")
        try renderComplication(family, state, name: "\(family.rawValue)_\(language)")
    }

    @Test(arguments: WatchComplicationFamily.allCases)
    func complicationNeedsPhone(family: WatchComplicationFamily) throws {
        try renderComplication(family, Self.state(birthDate: ""), name: "\(family.rawValue)_needs_phone")
    }

    /// The first screenful, as the watch shows it before scrolling (ScrollView does not render
    /// in ImageRenderer, so the content is clipped to the screen instead).
    private func renderScreen(_ state: WatchState, name: String) throws {
        let screen = Group {
            if let life = state.life {
                WatchLifeContent(state: state, life: life)
                    .padding(.top, 4)
                    .frame(width: Self.screen.width)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: Self.screen.width, height: Self.screen.height, alignment: .top)
                    .clipped()
            } else {
                WatchNeedsPhoneView(text: state.text, palette: state.palette)
                    .frame(width: Self.screen.width, height: Self.screen.height)
            }
        }
        .background(state.palette.background.color, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
        .padding(8)
        .background(Color.black)
        try render(screen, name: name)
    }

    private func renderComplication(_ family: WatchComplicationFamily, _ state: WatchState, name: String) throws {
        let size = Self.size(of: family)
        let content = WatchComplicationView(state: state, family: family)
            .foregroundStyle(.white)
            .frame(width: size.width, height: size.height)
            .background(Color(white: 0.18), in: RoundedRectangle(cornerRadius: family == .accessoryInline ? 6 : 12))
            .padding(8)
            .background(Color.black)
        try render(content, name: name)
    }

    private func render(_ view: some View, name: String) throws {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .dark).environment(\.displayScale, 2))
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        let directory = Self.outputDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("watch_\(name).png")
        let destination = try #require(
            CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
    }
}
