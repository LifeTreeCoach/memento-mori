package lifetree.coach.memento_mori_life_in_weeks.wear.complication

import lifetree.coach.memento_mori_life_in_weeks.wear.WatchState
import lifetree.coach.memento_mori_life_in_weeks.widget.LifePalette
import lifetree.coach.memento_mori_life_in_weeks.widget.WidgetInputs
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDate

class ComplicationContentTest {
    @Test
    fun `ranged value is percent lived with the ungrouped week number`() {
        val state = WatchState.from(
            WidgetInputs.fromValues(mapOf("birth_date" to "1990-03-15", "language" to "en")),
            LocalDate.of(2026, 11, 2),
        )
        val content = ComplicationContent.from(state, weekPrefix = "W")!!
        assertEquals(1911f / 4160f * 100f, content.value, 1e-3f)
        assertEquals("1912", content.rangedText)
        assertEquals("W1912", content.shortText)
        assertEquals(LifePalette.STOIC_DARK.accent, content.rangeColor)
    }

    @Test
    fun `ranged value colour follows the theme style`() {
        val state = WatchState.from(
            WidgetInputs.fromValues(mapOf("birth_date" to "1990-03-15", "theme_style" to "warm", "brightness" to "light")),
            LocalDate.of(2026, 11, 2),
        )
        assertEquals(LifePalette.WARM_DARK.accent, ComplicationContent.from(state, weekPrefix = "W")!!.rangeColor)
    }

    @Test
    fun `no data without inputs`() {
        assertNull(ComplicationContent.from(WatchState.NeedsPhone("en"), weekPrefix = "W"))
    }

    @Test
    fun `short text uses the localized week prefix`() {
        val state = WatchState.from(
            WidgetInputs.fromValues(mapOf("birth_date" to "1990-03-15", "language" to "fr")),
            LocalDate.of(2026, 11, 2),
        )
        assertEquals("S1912", ComplicationContent.from(state, weekPrefix = "S")!!.shortText)
        assertEquals("S1912", ComplicationContent.shortText("S", 1912))
        assertEquals("W1912", ComplicationContent.preview("W").shortText)
    }
}
