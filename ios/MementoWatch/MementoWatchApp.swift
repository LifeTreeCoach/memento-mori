import LifeCore
import MementoWatchUI
import SwiftUI

/// Apple Watch app. The iPhone sends the widget inputs via WatchConnectivity
/// (Runner/WatchSync.swift); `WatchInputsStore` caches them in the App Group for the app and
/// its complications, which compute everything with LifeCore (docs/widget-data-contract.md).
@main
struct MementoWatchApp: App {
    @StateObject private var store = WatchInputsStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchLifeView(state: WatchState(inputs: store.inputs, today: store.today))
                .onAppear { store.activate() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.refreshToday() }
                }
        }
    }
}
