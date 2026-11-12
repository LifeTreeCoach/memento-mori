package lifetree.coach.memento_mori_life_in_weeks.widget

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.ZoneId
import java.time.ZonedDateTime

/** Shared pure helpers: number formatting, next local midnight and the palette. */
class LocalFormatTest {
    @Test
    fun `numbers are grouped per language`() {
        assertEquals("1,912", LocalizedNumbers("en").format(1912))
        assertEquals("1.912", LocalizedNumbers("de").format(1912))
        // French groups with U+202F (narrow no-break space, CLDR); pinned to what the JVM gives.
        assertEquals("1\u202F912", LocalizedNumbers("fr").format(1912))
        assertEquals("29\u202F120", LocalizedNumbers("fr").format(29120))
        // Spanish 4-digit numbers are grouped on the JVM and on Android ("1.912", checked on Wear OS);
        // Apple Foundation follows CLDR minimumGroupingDigits = 2 and prints "1912" on iOS.
        assertEquals("1.912", LocalizedNumbers("es").format(1912))
        assertEquals("29.120", LocalizedNumbers("es").format(29120))
    }

    @Test
    fun `next local midnight is the start of the next day`() {
        val zone = ZoneId.of("Europe/Berlin")
        val now = ZonedDateTime.of(2026, 11, 2, 23, 30, 0, 0, zone)
        assertEquals(ZonedDateTime.of(2026, 11, 3, 0, 0, 0, 0, zone), nextLocalMidnight(now))
        val midnight = ZonedDateTime.of(2026, 10, 25, 0, 0, 0, 0, zone)
        assertEquals(ZonedDateTime.of(2026, 10, 26, 0, 0, 0, 0, zone), nextLocalMidnight(midnight))
    }

    @Test
    fun `style defaults are recognised and tones follow the style`() {
        assertEquals(LifePalette.STOIC_LIGHT to LifePalette.STOIC_DARK, LifePalette.tones(WidgetInputs.ThemeStyle.STOIC))
        assertEquals(LifePalette.WARM_LIGHT to LifePalette.WARM_DARK, LifePalette.tones(WidgetInputs.ThemeStyle.WARM))
        assertEquals(
            setOf(0xFF1F1E1C.toInt(), 0xFFA39D92.toInt(), 0xFFEFA27F.toInt(), 0xFFE6936E.toInt()),
            LifePalette.STYLE_DEFAULT_LIVED,
        )
    }
}
