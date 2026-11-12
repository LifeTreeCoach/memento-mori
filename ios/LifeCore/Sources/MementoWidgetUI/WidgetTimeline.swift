import Foundation

/// When the widget redraws: now, then at each of the next local midnights, so the week
/// number and grid roll over without the app running.
public enum WidgetTimeline {
    public static let midnightsAhead = 7

    public static func entryDates(
        from now: Date,
        midnights: Int = midnightsAhead,
        calendar: Calendar = .current
    ) -> [Date] {
        var dates = [now]
        var day = calendar.startOfDay(for: now)
        for _ in 0..<midnights {
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            dates.append(next)
            day = next
        }
        return dates
    }
}
