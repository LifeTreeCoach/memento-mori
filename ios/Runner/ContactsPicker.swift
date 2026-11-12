import ContactsUI
import Flutter
import UIKit

/// MethodChannel `memento/contacts_picker` (lib/people_import/picked_contacts_source.dart):
/// `isSupported` -> true, `pickContacts` -> the system contact picker
/// (`CNContactPickerViewController`, needs no contacts permission; only the chosen
/// contacts are shared). Multi-select; only contacts with a birthday can be chosen.
/// Cancel returns an empty list.
final class ContactsPicker: NSObject, CNContactPickerDelegate {
    static let shared = ContactsPicker()
    static let channelName = "memento/contacts_picker"

    /// The Dart call waiting for the open picker.
    private var pendingResult: FlutterResult?

    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "isSupported": result(true)
            case "pickContacts": self?.pickContacts(result)
            default: result(FlutterMethodNotImplemented)
            }
        }
    }

    private func pickContacts(_ result: @escaping FlutterResult) {
        guard pendingResult == nil else {
            result(FlutterError(code: "busy", message: "The contact picker is already open", details: nil))
            return
        }
        guard let presenter = Self.topViewController() else {
            result(FlutterError(code: "no_view", message: "No view controller to present from", details: nil))
            return
        }
        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.predicateForEnablingContact = NSPredicate(format: "birthday != nil")
        pendingResult = result
        presenter.present(picker, animated: true)
    }

    // MARK: CNContactPickerDelegate

    /// Implementing the plural variant turns on multi-select.
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        finish(with: contacts.compactMap(PickedContact.channelMap(for:)))
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        finish(with: [])
    }

    private func finish(with maps: [[String: Any]]) {
        let result = pendingResult
        pendingResult = nil
        result?(maps.map { map in
            map.mapValues { value -> Any in
                if let data = value as? Data { return FlutterStandardTypedData(bytes: data) }
                return value
            }
        })
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows)
        var top = (windows.first(where: \.isKeyWindow) ?? windows.first)?.rootViewController
        while let presented = top?.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }
}
