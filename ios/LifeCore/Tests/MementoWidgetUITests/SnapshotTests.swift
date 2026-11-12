import Foundation
import ImageIO
import LifeCore
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import MementoWidgetUI

/// Renders every widget family to PNG for visual review (not compared against references).
/// Output: $WIDGET_SNAPSHOT_DIR, else <tmp>/MementoWidgetSnapshots, as ios_widget_<name>.png.
@MainActor
struct SnapshotTests {
    static let today = CivilDate(year: 2026, month: 11, day: 2)!

    static func inputs(language: String = "en", style: String = "stoic", brightness: String = "system",
                       birthDate: String = "1990-03-15", mode: String = "weeks") -> WidgetInputs {
        WidgetInputs(values: [
            "birth_date": birthDate, "language": language, "theme_style": style,
            "brightness": brightness, "widget_display_mode": mode,
            "color_lived": 0xFF1F_1E1C, "color_remaining": 0xFFE3_DED3,
        ])
    }

    /// iPhone 6.1" widget sizes in points.
    static func size(of family: MementoWidgetFamily) -> CGSize {
        switch family {
        case .systemSmall: return CGSize(width: 158, height: 158)
        case .systemMedium: return CGSize(width: 338, height: 158)
        case .systemLarge: return CGSize(width: 338, height: 354)
        case .accessoryCircular: return CGSize(width: 72, height: 72)
        case .accessoryRectangular: return CGSize(width: 160, height: 72)
        case .accessoryInline: return CGSize(width: 234, height: 26)
        }
    }

    static var outputDirectory: URL {
        if let path = ProcessInfo.processInfo.environment["WIDGET_SNAPSHOT_DIR"] {
            return URL(fileURLWithPath: path)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("MementoWidgetSnapshots")
    }

    @Test(arguments: MementoWidgetFamily.allCases)
    func stoicEnglishLight(family: MementoWidgetFamily) throws {
        try render(family, Self.inputs(), dark: false, name: "\(family.rawValue)_en_light")
    }

    @Test(arguments: MementoWidgetFamily.allCases)
    func stoicGermanDark(family: MementoWidgetFamily) throws {
        try render(family, Self.inputs(language: "de", mode: "years"), dark: true, name: "\(family.rawValue)_de_dark")
    }

    /// Longest French phrasing: 4-digit grouped week count ("encore 2 284 semaines").
    @Test(arguments: MementoWidgetFamily.allCases)
    func stoicFrenchLight(family: MementoWidgetFamily) throws {
        let inputs = Self.inputs(language: "fr", birthDate: "1990-11-17")
        try render(family, inputs, dark: false, name: "\(family.rawValue)_fr_light")
    }

    /// Spanish in days mode: the longest remaining count ("quedan 16.086 días").
    @Test(arguments: MementoWidgetFamily.allCases)
    func stoicSpanishDark(family: MementoWidgetFamily) throws {
        let inputs = Self.inputs(language: "es", birthDate: "1990-11-17", mode: "days")
        try render(family, inputs, dark: true, name: "\(family.rawValue)_es_dark")
    }

    @Test(arguments: [MementoWidgetFamily.systemSmall, .systemMedium, .accessoryRectangular], ["fr", "es"])
    func setupTranslated(family: MementoWidgetFamily, language: String) throws {
        try render(family, Self.inputs(language: language, birthDate: ""), dark: false, name: "\(family.rawValue)_setup_\(language)")
    }

    @Test(arguments: [MementoWidgetFamily.systemSmall, .systemMedium, .systemLarge])
    func warmLight(family: MementoWidgetFamily) throws {
        let inputs = Self.inputs(style: "warm", brightness: "light")
        try render(family, inputs, dark: true, name: "\(family.rawValue)_warm_light")
    }

    @Test(arguments: [MementoWidgetFamily.systemSmall, .systemMedium, .accessoryRectangular])
    func setup(family: MementoWidgetFamily) throws {
        try render(family, Self.inputs(birthDate: ""), dark: false, name: "\(family.rawValue)_setup")
    }

    private func render(_ family: MementoWidgetFamily, _ inputs: WidgetInputs, dark: Bool, name: String) throws {
        let size = Self.size(of: family)
        let content = MementoWidgetView(inputs: inputs, today: Self.today, family: family)
        let framed = Group {
            if family.isAccessory {
                content
                    .foregroundStyle(.white)
                    .padding(family == .accessoryInline ? 4 : 0)
                    .frame(width: size.width, height: size.height)
                    .background(Color(white: 0.25), in: RoundedRectangle(cornerRadius: 12))
            } else {
                content
                    .padding(16)
                    .frame(width: size.width, height: size.height)
                    .background(
                        MementoWidgetView.background(for: inputs, systemIsDark: dark),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
            }
        }
        .padding(8)
        .environment(\.colorScheme, dark ? .dark : .light)
        .environment(\.displayScale, 3)

        let renderer = ImageRenderer(content: framed)
        renderer.scale = 3
        let image = try #require(renderer.cgImage)
        #expect(image.width == Int((size.width + 16) * 3))
        try writePNG(image, name: name)
    }

    private func writePNG(_ image: CGImage, name: String) throws {
        let directory = Self.outputDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("ios_widget_\(name).png")
        let destination = try #require(
            CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
    }
}
