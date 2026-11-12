import CoreGraphics
import LifeCore
import Testing
@testable import MementoWidgetUI

/// Must match android/app/src/test/.../LifeGridRendererTest.kt behaviour.
struct LifeGridGeometryTests {
    let calc = LifeCalculator(
        birthDate: CivilDate(year: 1990, month: 3, day: 15)!,
        today: CivilDate(year: 2026, month: 11, day: 2)!
    )

    @Test func weekGridHasOneRowPerYearAndFitsTheArea() {
        let geometry = LifeGridGeometry.weekGrid(calc, in: CGSize(width: 306, height: 230))
        #expect(geometry.columns == 52)
        #expect(geometry.rows == 80)
        #expect(geometry.tickColumns == 2)
        #expect(geometry.size.width <= 306.001)
        #expect(geometry.size.height <= 230.001)
        #expect(geometry.pitchX <= geometry.pitchY * 1.6 + 0.001)
    }

    @Test func weekGridMarksTheCurrentWeek() {
        let geometry = LifeGridGeometry.weekGrid(calc, in: CGSize(width: 300, height: 300))
        #expect(geometry.cell(at: calc.weeksLived - 1) == .lived)
        #expect(geometry.cell(at: calc.weeksLived) == .current)
        #expect(geometry.cell(at: calc.weeksLived + 1) == .remaining)
    }

    @Test func yearStripWrapsToTheBiggestCells() {
        // Short and wide: 2 rows of 40.
        #expect(LifeGridGeometry.yearStrip(calc, in: CGSize(width: 306, height: 20)).rows == 2)
        // Medium widget strip (~306 x 51 pt): 4 rows of 20.
        let medium = LifeGridGeometry.yearStrip(calc, in: CGSize(width: 306, height: 51))
        #expect(medium.rows == 4)
        #expect(medium.columns == 20)
        #expect(medium.livedCount == calc.yearsLived)
        // Tall: decades (8 rows of 10).
        #expect(LifeGridGeometry.yearStrip(calc, in: CGSize(width: 150, height: 150)).rows == 8)
    }

    @Test func degenerateSizesDoNotCrash() {
        #expect(LifeGridGeometry.weekGrid(calc, in: .zero).rows == 80)
        #expect(LifeGridGeometry.yearStrip(calc, in: .zero).cells == 80)
    }
}
