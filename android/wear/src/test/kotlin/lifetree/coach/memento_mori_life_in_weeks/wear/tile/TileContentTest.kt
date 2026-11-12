package lifetree.coach.memento_mori_life_in_weeks.wear.tile

import lifetree.coach.memento_mori_life_in_weeks.wear.WatchState
import lifetree.coach.memento_mori_life_in_weeks.widget.WidgetInputs
import org.junit.Assert.assertEquals
import org.junit.Test

class TileContentTest {
    private fun ready(language: String) = WatchState.Ready(
        language = language,
        displayMode = WidgetInputs.DisplayMode.WEEKS,
        weekNumber = 1912,
        totalWeeks = 4160,
        percentLived = 45,
        progress = 0.4596f,
        remaining = 2249,
        yearsLived = 36,
        totalYears = 80,
    )

    @Test
    fun `tile shows the grouped week number and percent`() {
        val content = TileContent.from(ready("en")) as TileContent.Progress
        assertEquals("1,912", content.weekNumber)
        assertEquals(45, content.percentLived)
        assertEquals(0.4596f * 360f, content.sweepDegrees, 1e-3f)
        assertEquals("1.912", (TileContent.from(ready("de")) as TileContent.Progress).weekNumber)
    }

    @Test
    fun `tile groups the week number in French and Spanish`() {
        assertEquals("1\u202F912", (TileContent.from(ready("fr")) as TileContent.Progress).weekNumber)
        assertEquals("1.912", (TileContent.from(ready("es")) as TileContent.Progress).weekNumber)
    }

    @Test
    fun `tile asks for the phone without inputs`() {
        assertEquals(TileContent.NeedsPhone, TileContent.from(WatchState.NeedsPhone("de")))
    }
}
