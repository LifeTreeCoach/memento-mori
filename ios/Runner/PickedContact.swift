import Contacts
import Foundation

/// Maps a contact chosen in the system contact picker to the map sent over
/// `memento/contacts_picker` (see lib/people_import/picked_contacts_source.dart,
/// same shape as Android's `PickedContact.toChannelMap`):
/// `id` (CNContact identifier, as flutter_contacts uses), `displayName`,
/// `birthday` (`yyyy-MM-dd`, `--MM-dd` without a year, empty without a birthday)
/// and `thumbnail` (only with a birthday, so no photo bytes are sent for nothing).
///
/// Picker contacts are partial: every key is checked with `isKeyAvailable`, because
/// reading a key that was not fetched raises an Objective-C exception.
enum PickedContact {
    /// Year Apple stores for birthdays without a year (`X-APPLE-OMIT-YEAR`).
    static let noYearMarker = 1604

    /// The channel map, or nil for a contact without a name (Dart ignores those anyway).
    static func channelMap(for contact: CNContact) -> [String: Any]? {
        guard let name = displayName(of: contact) else { return nil }
        let birthday = birthdayText(of: contact)
        var map: [String: Any] = [
            "id": contact.identifier,
            "displayName": name,
            "birthday": birthday,
        ]
        if !birthday.isEmpty, let thumbnail = thumbnail(of: contact) {
            map["thumbnail"] = thumbnail
        }
        return map
    }

    /// `yyyy-MM-dd`, `--MM-dd` without (or with Apple's marker) year, or "" when unusable.
    static func birthdayText(month: Int?, day: Int?, year: Int?) -> String {
        guard let month, let day, (1...12).contains(month), (1...31).contains(day) else { return "" }
        let monthDay = String(format: "%02d-%02d", month, day)
        guard let year, year != noYearMarker, year > 0 else { return "--\(monthDay)" }
        return String(format: "%04d-", year) + monthDay
    }

    static func displayName(of contact: CNContact) -> String? {
        let descriptor = CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        var name: String?
        if contact.areKeysAvailable([descriptor]) {
            name = CNContactFormatter.string(from: contact, style: .fullName)
        }
        if (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            name = fallbackName(of: contact)
        }
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func fallbackName(of contact: CNContact) -> String? {
        var parts: [String] = []
        if contact.isKeyAvailable(CNContactGivenNameKey) { parts.append(contact.givenName) }
        if contact.isKeyAvailable(CNContactFamilyNameKey) { parts.append(contact.familyName) }
        let joined = parts.filter { !$0.isEmpty }.joined(separator: " ")
        if !joined.isEmpty { return joined }
        if contact.isKeyAvailable(CNContactOrganizationNameKey) { return contact.organizationName }
        return nil
    }

    private static func birthdayText(of contact: CNContact) -> String {
        guard contact.isKeyAvailable(CNContactBirthdayKey), let birthday = contact.birthday else {
            return ""
        }
        return birthdayText(month: birthday.month, day: birthday.day, year: birthday.year)
    }

    private static func thumbnail(of contact: CNContact) -> Data? {
        guard contact.isKeyAvailable(CNContactThumbnailImageDataKey),
              let data = contact.thumbnailImageData, !data.isEmpty else { return nil }
        return data
    }
}
