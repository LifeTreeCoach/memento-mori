package lifetree.coach.memento_mori_life_in_weeks.wear

import lifetree.coach.memento_mori_life_in_weeks.widget.LifeCalculator
import lifetree.coach.memento_mori_life_in_weeks.widget.LifePalette
import lifetree.coach.memento_mori_life_in_weeks.widget.WidgetInputs
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime

/** Pure watch logic: state, formatting, years strip and refresh timing. */
class WatchStateTest {
    private val today = LocalDate.of(2026, 11, 2)
    private val birthDate = LocalDate.of(1990, 3, 15)

    private fun inputs(vararg values: Pair<String, Any>) = WidgetInputs.fromValues(mapOf(*values), deviceLanguage = "de")

    @Test
    fun `missing birth date asks for the phone app in the chosen or device language`() {
        assertEquals(WatchState.NeedsPhone("en"), WatchState.from(inputs("language" to "en"), today))
        assertEquals(WatchState.NeedsPhone("de"), WatchState.from(inputs("birth_date" to ""), today))
        assertEquals(WatchState.NeedsPhone("fr"), WatchState.from(inputs("language" to "fr"), today))
        assertEquals(WatchState.NeedsPhone("es"), WatchState.from(inputs("language" to "es"), today))
    }

    @Test
    fun `palette is the dark variant of the synced theme style`() {
        assertEquals(LifePalette.STOIC_DARK, WatchState.from(inputs("birth_date" to "1990-03-15"), today).palette)
        assertEquals(
            LifePalette.WARM_DARK,
            WatchState.from(inputs("birth_date" to "1990-03-15", "theme_style" to "warm", "brightness" to "light"), today).palette,
        )
        assertEquals(LifePalette.WARM_DARK, WatchState.from(inputs("theme_style" to "warm"), today).palette)
    }

    @Test
    fun `ready state matches LifeCalculator`() {
        val state = WatchState.from(
            inputs("birth_date" to "1990-03-15", "life_expectancy_years" to 90, "language" to "en"),
            today,
        ) as WatchState.Ready
        val calc = LifeCalculator(birthDate, 90, today)
        assertEquals(calc.currentWeekNumber, state.weekNumber)
        assertEquals(1912, state.weekNumber)
        assertEquals(4680, state.totalWeeks)
        assertEquals(40, state.percentLived)
        assertEquals(calc.weeksRemaining, state.remaining)
        assertEquals((calc.percentLived / 100).toFloat(), state.progress, 1e-6f)
        assertEquals(36, state.yearsLived)
        assertEquals(90, state.totalYears)
    }

    @Test
    fun `remaining follows the display mode`() {
        val state = WatchState.from(
            inputs("birth_date" to "1990-03-15", "widget_display_mode" to "years"),
            today,
        ) as WatchState.Ready
        assertEquals(WidgetInputs.DisplayMode.YEARS, state.displayMode)
        assertEquals(44, state.remaining)
    }

    @Test
    fun `years strip marks lived, current and remaining years`() {
        val strip = YearsStrip(yearsLived = 36, totalYears = 80)
        assertEquals(8, strip.rows)
        assertEquals(YearsStrip.Dot.LIVED, strip.dot(35))
        assertEquals(YearsStrip.Dot.CURRENT, strip.dot(36))
        assertEquals(YearsStrip.Dot.REMAINING, strip.dot(37))
        assertEquals(9, YearsStrip(0, 85).rows)
    }

    @Test
    fun `millis until next midnight`() {
        val zone = ZoneId.of("Europe/Berlin")
        val now = ZonedDateTime.of(2026, 11, 2, 23, 30, 0, 0, zone)
        assertEquals(30 * 60 * 1000L, WatchRefresh.millisUntilNextMidnight(now))
        // DST end: 2026-10-25 has 25 hours in Berlin.
        val dst = ZonedDateTime.of(2026, 10, 25, 0, 0, 0, 0, zone)
        assertEquals(25 * 3600 * 1000L, WatchRefresh.millisUntilNextMidnight(dst))
        assertTrue(WatchRefresh.millisUntilNextMidnight(ZonedDateTime.now()) > 0)
    }
}
