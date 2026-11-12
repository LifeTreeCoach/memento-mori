import Foundation
import Testing
@testable import MementoWidgetUI

struct WidgetTimelineTests {
    @Test func entriesAreNowThenEachLocalMidnight() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        // 2026-10-24 15:30 local; Berlin leaves DST on 2026-10-25 (that day has 25 hours).
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 15, minute: 30)))
        let dates = WidgetTimeline.entryDates(from: now, midnights: 3, calendar: calendar)
        #expect(dates.count == 4)
        #expect(dates[0] == now)
        for (offset, date) in dates.dropFirst().enumerated() {
            let parts = calendar.dateComponents([.day, .hour, .minute], from: date)
            #expect(parts.day == 25 + offset)
            #expect(parts.hour == 0)
            #expect(parts.minute == 0)
        }
    }
}
