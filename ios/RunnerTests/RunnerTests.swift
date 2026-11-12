import Contacts
import Flutter
import UIKit
import XCTest

@testable import Runner

class RunnerTests: XCTestCase {

  func testExample() {
    // If you add code to the Runner application, consider adding tests here.
    // See https://developer.apple.com/documentation/xctest for more information about using XCTest.
  }

  // MARK: PickedContact (memento/contacts_picker)

  func testBirthdayTextWithYear() {
    XCTAssertEqual(PickedContact.birthdayText(month: 5, day: 1, year: 1990), "1990-05-01")
  }

  func testBirthdayTextWithoutYear() {
    XCTAssertEqual(PickedContact.birthdayText(month: 2, day: 29, year: nil), "--02-29")
    XCTAssertEqual(PickedContact.birthdayText(month: 12, day: 24, year: 1604), "--12-24")
  }

  func testBirthdayTextUnusable() {
    XCTAssertEqual(PickedContact.birthdayText(month: nil, day: 3, year: 1990), "")
    XCTAssertEqual(PickedContact.birthdayText(month: 13, day: 3, year: 1990), "")
  }

  func testChannelMapOfContactWithBirthdayAndPhoto() {
    let contact = CNMutableContact()
    contact.givenName = "Ada"
    contact.familyName = "Lovelace"
    contact.birthday = DateComponents(year: 1815, month: 12, day: 10)
    contact.imageData = Self.pngData()
    let map = PickedContact.channelMap(for: contact)
    XCTAssertEqual(map?["id"] as? String, contact.identifier)
    XCTAssertEqual(map?["displayName"] as? String, "Ada Lovelace")
    XCTAssertEqual(map?["birthday"] as? String, "1815-12-10")
  }

  func testChannelMapWithoutBirthdayHasNoThumbnail() {
    let contact = CNMutableContact()
    contact.givenName = "Grace"
    let map = PickedContact.channelMap(for: contact)
    XCTAssertEqual(map?["birthday"] as? String, "")
    XCTAssertNil(map?["thumbnail"])
  }

  func testChannelMapSkipsNamelessContact() {
    let contact = CNMutableContact()
    contact.birthday = DateComponents(month: 1, day: 2)
    XCTAssertNil(PickedContact.channelMap(for: contact))
  }

  private static func pngData() -> Data? {
    UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).pngData { context in
      UIColor.red.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    }
  }
}
