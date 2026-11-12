import Flutter
import Foundation
import LifeCore
import WatchConnectivity

/// Sends the widget inputs to the Apple Watch app (docs/widget-data-contract.md, "Apple Watch").
/// Reads the contract keys the Flutter app published to the App Group and pushes them with
/// `updateApplicationContext` (only the latest context is delivered: last inputs win), plus
/// `updated_at`. Triggered by Flutter after each publish (method channel `memento/watch_sync`),
/// on scene activation and when the session activates; a trigger whose contract values equal
/// the last context sent to this watch (`session.applicationContext`) sends nothing.
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()
    static let channelName = "memento/watch_sync"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetInputs.appGroup) ?? .standard
    }

    func activate() {
        guard WCSession.isSupported(), WCSession.default.delegate == nil else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Lets lib/widget_service.dart request a sync after publishing the inputs.
    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            guard call.method == "sync" else {
                result(FlutterMethodNotImplemented)
                return
            }
            self?.sync()
            result(nil)
        }
    }

    /// `force` resends unchanged inputs (a watch app was just installed or paired).
    func sync(force: Bool = false) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        // Not activated yet: the activation callback syncs.
        guard session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }
        var context = WidgetInputs.contractValues(in: defaults)
        guard force || !Self.sameInputs(context, session.applicationContext) else { return }
        context[Self.updatedAtKey] = Int64(Date().timeIntervalSince1970 * 1000)
        do {
            try session.updateApplicationContext(context)
        } catch {
            NSLog("WatchSync: updateApplicationContext failed: \(error.localizedDescription)")
        }
    }

    private static let updatedAtKey = "updated_at"

    /// Compares contract values, ignoring the send timestamp.
    private static func sameInputs(_ values: [String: Any], _ lastSent: [String: Any]) -> Bool {
        var previous = lastSent
        previous.removeValue(forKey: updatedAtKey)
        return NSDictionary(dictionary: values).isEqual(to: previous)
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        if let error {
            NSLog("WatchSync: activation failed: \(error.localizedDescription)")
        }
        sync()
    }

    /// Covers pairing a watch or installing the watch app after the inputs were published.
    func sessionWatchStateDidChange(_ session: WCSession) {
        sync(force: true)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    /// Switching to another paired watch: activate again for the new one.
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
