import CoreGraphics
import LifeCore

/// Cell layout of a life grid, mirroring android/app/.../widget/LifeGridRenderer.kt so both
/// widgets look the same. Sizes are in points; the grid is centred in its frame by the view.
public struct LifeGridGeometry: Equatable, Sendable {
    public enum Cell: Sendable { case lived, current, remaining }

    public static let gapRatio: CGFloat = 0.25
    static let maxCellAspect: CGFloat = 1.6
    static let tickColumns = 2
    static let yearsPerTick = 10
    /// Row counts the medium widget's year strip may wrap into (8 rows of 10 = decades).
    static let stripRowOptions = [1, 2, 4, 8]

    public let columns: Int
    public let rows: Int
    public let pitchX: CGFloat
    public let pitchY: CGFloat
    public let tickColumns: Int
    /// May be fewer than columns x rows; the trailing slots stay empty.
    public let cells: Int
    /// Index of the first non-lived cell (it is the "current" cell).
    public let livedCount: Int

    public var size: CGSize {
        CGSize(width: CGFloat(columns + tickColumns) * pitchX, height: CGFloat(rows) * pitchY)
    }

    var originX: CGFloat { CGFloat(tickColumns) * pitchX }

    public func cell(at index: Int) -> Cell {
        if index < livedCount { return .lived }
        return index == livedCount ? .current : .remaining
    }

    /// The app's week grid: one row per year, 52 weeks per row, decade ticks on the left;
    /// square cells, widened up to `maxCellAspect` to use spare width.
    public static func weekGrid(_ calc: LifeCalculator, in size: CGSize) -> LifeGridGeometry {
        let rows = max(calc.totalYears, 1)
        let units = CGFloat(LifeCalculator.weeksPerYear + tickColumns)
        let width = max(size.width, units)
        let height = max(size.height, CGFloat(rows))
        let square = min(width / units, height / CGFloat(rows))
        return LifeGridGeometry(
            columns: LifeCalculator.weeksPerYear, rows: rows,
            pitchX: min(width / units, square * maxCellAspect), pitchY: square,
            tickColumns: tickColumns, cells: rows * LifeCalculator.weeksPerYear, livedCount: calc.weeksLived
        )
    }

    /// One cell per year, wrapped into the row count that gives the biggest cells:
    /// 2 x 40 when short, more rows when taller.
    public static func yearStrip(_ calc: LifeCalculator, in size: CGSize) -> LifeGridGeometry {
        let cells = max(calc.totalYears, 1)
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        // First option with the biggest pitch (like Kotlin's maxBy).
        let rows = stripRowOptions.reduce(stripRowOptions[0]) { best, option in
            squarePitch(cells: cells, rows: option, width: width, height: height)
                > squarePitch(cells: cells, rows: best, width: width, height: height) ? option : best
        }
        let columns = Int((Double(cells) / Double(rows)).rounded(.up))
        let square = squarePitch(cells: cells, rows: rows, width: width, height: height)
        return LifeGridGeometry(
            columns: columns, rows: rows,
            pitchX: min(width / CGFloat(columns), square * maxCellAspect), pitchY: square,
            tickColumns: 0, cells: cells, livedCount: calc.yearsLived
        )
    }

    private static func squarePitch(cells: Int, rows: Int, width: CGFloat, height: CGFloat) -> CGFloat {
        let columns = (Double(cells) / Double(rows)).rounded(.up)
        return min(width / CGFloat(columns), height / CGFloat(rows))
    }
}
