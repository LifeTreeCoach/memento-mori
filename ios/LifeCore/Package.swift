// swift-tools-version: 6.0
// Shared life calculation and widget views for the iOS widget and watch targets
// (docs/widget-data-contract.md). macOS is listed only so `swift test` runs on the Mac.
// iOS 15 is the Runner app's minimum (Runner/WatchSync.swift links LifeCore); the widget
// extensions are iOS 17 / watchOS 10, so views using iOS 16 APIs are marked @available.
import PackageDescription

let package = Package(
    name: "LifeCore",
    platforms: [.iOS(.v15), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "LifeCore", targets: ["LifeCore"]),
        .library(name: "MementoWidgetUI", targets: ["MementoWidgetUI"]),
        .library(name: "MementoWatchUI", targets: ["MementoWatchUI"]),
    ],
    targets: [
        .target(name: "LifeCore"),
        // SwiftUI views of the home-screen widget plus the timeline provider shared with the
        // watch complications (LifeTimelineProvider); the WidgetKit extensions only host them.
        .target(name: "MementoWidgetUI", dependencies: ["LifeCore"]),
        // SwiftUI views of the Apple Watch app and its complications (ios/MementoWatch*).
        .target(name: "MementoWatchUI", dependencies: ["LifeCore"]),
        // Reads the shared fixture test/fixtures/life_calculator_vectors.json via #filePath.
        .testTarget(name: "LifeCoreTests", dependencies: ["LifeCore"]),
        // Geometry tests plus PNG snapshots of every widget family (see SnapshotTests.swift).
        .testTarget(name: "MementoWidgetUITests", dependencies: ["MementoWidgetUI"]),
        // Watch view state plus PNG snapshots of the watch app and complications.
        .testTarget(name: "MementoWatchUITests", dependencies: ["MementoWatchUI"]),
    ]
)
