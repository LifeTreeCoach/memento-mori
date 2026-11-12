import Foundation
import LifeCore
import WatchConnectivity
import WidgetKit

/// Receives the iPhone's widget inputs (`updateApplicationContext` from Runner/WatchSync.swift),
/// caches them in the App Group shared with the complications and publishes them to the UI.
/// The cache lets the watch recompute every day without the phone being reachable.
final class WatchInputsStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var inputs: WidgetInputs
    /// Recomputed whenever the app becomes active, so the week rolls over after midnight.
    @Published private(set) var today = CivilDate.today()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = UserDefaults(suiteName: WidgetInputs.appGroup) ?? .standard) {
        self.defaults = defaults
        inputs = WidgetInputs(defaults: defaults)
        super.init()
    }

    func activate() {
        guard WCSession.isSupported(), WCSession.default.delegate == nil else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func refreshToday() {
        today = CivilDate.today()
    }

    // MARK: WCSessionDelegate (called on a background queue)

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        if let error {
            NSLog("WatchInputsStore: activation failed: \(error.localizedDescription)")
        }
        // The last context the phone sent, e.g. while this app was not running.
        let context = session.receivedApplicationContext
        if !context.isEmpty {
            store(context)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        store(applicationContext)
    }

    private func store(_ context: [String: Any]) {
        WidgetInputs.store(context, in: defaults)
        let received = WidgetInputs(defaults: defaults)
        WidgetCenter.shared.reloadAllTimelines()
        DispatchQueue.main.async {
            self.inputs = received
            self.today = CivilDate.today()
        }
    }
}
