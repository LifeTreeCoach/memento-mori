package lifetree.coach.memento_mori_life_in_weeks.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

/** Decoding of the home_widget key/value map (docs/widget-data-contract.md). */
class WidgetInputsTest {
    @Test
    fun `decodes all contract keys`() {
        val inputs = WidgetInputs.fromValues(
            mapOf(
                "birth_date" to "1990-11-17",
                "life_expectancy_years" to 90,
                "widget_display_mode" to "months",
                "language" to "en",
                "theme_style" to "warm",
                "brightness" to "dark",
                "color_lived" to 0xFF112233L,
                "color_remaining" to 0x00FFFFFF,
                "color_accent" to "4278190335",
            ),
        )
        assertEquals(LocalDate.of(1990, 11, 17), inputs.birthDate)
        assertEquals(90, inputs.lifeExpectancyYears)
        assertEquals(WidgetInputs.DisplayMode.MONTHS, inputs.displayMode)
        assertEquals("en", inputs.language)
        assertEquals(WidgetInputs.ThemeStyle.WARM, inputs.themeStyle)
        assertEquals(WidgetInputs.Brightness.DARK, inputs.brightness)
        assertEquals(0xFF112233L.toInt(), inputs.colorLived)
        assertEquals(0x00FFFFFF, inputs.colorRemaining)
        assertEquals(0xFF0000FFL.toInt(), inputs.colorAccent)
        assertTrue(inputs.isConfigured)
    }

    @Test
    fun `missing values fall back to defaults`() {
        val inputs = WidgetInputs.fromValues(
            mapOf("birth_date" to "", "life_expectancy_years" to 0, "language" to "it", "brightness" to "dim"),
            deviceLanguage = "de",
        )
        assertNull(inputs.birthDate)
        assertFalse(inputs.isConfigured)
        assertNull(inputs.calculator())
        assertEquals(LifeCalculator.DEFAULT_LIFE_EXPECTANCY_YEARS, inputs.lifeExpectancyYears)
        assertEquals(WidgetInputs.DisplayMode.WEEKS, inputs.displayMode)
        assertEquals("de", inputs.language)
        assertEquals(WidgetInputs.ThemeStyle.STOIC, inputs.themeStyle)
        assertEquals(WidgetInputs.Brightness.SYSTEM, inputs.brightness)
        assertEquals(WidgetInputs.DEFAULT_ACCENT, inputs.colorAccent)
    }

    @Test
    fun `decodes the optional dark colours`() {
        val inputs = WidgetInputs.fromValues(
            mapOf("color_lived_dark" to 0xFFAABBCCL, "color_remaining_dark" to 0xFF101112L.toInt(), "color_accent_dark" to "4294955146"),
        )
        assertEquals(0xFFAABBCCL.toInt(), inputs.colorLivedDark)
        assertEquals(0xFF101112L.toInt(), inputs.colorRemainingDark)
        assertEquals(0xFFFFD08AL.toInt(), inputs.colorAccentDark)
    }

    @Test
    fun `missing dark colours stay null`() {
        val inputs = WidgetInputs.fromValues(mapOf("color_lived" to 0xFF112233L))
        assertNull(inputs.colorLivedDark)
        assertNull(inputs.colorRemainingDark)
        assertNull(inputs.colorAccentDark)
    }

    @Test
    fun `contractValues forwards the dark colours`() {
        val values = WidgetInputs.contractValues(mapOf("color_lived_dark" to 1, "color_remaining_dark" to 2, "color_accent_dark" to 3))
        assertEquals(mapOf("color_lived_dark" to 1, "color_remaining_dark" to 2, "color_accent_dark" to 3), values)
    }

    @Test
    fun `missing language follows the device language`() {
        assertEquals("de", WidgetInputs.fromValues(emptyMap<String, Any>(), deviceLanguage = "de").language)
        assertEquals("fr", WidgetInputs.fromValues(emptyMap<String, Any>(), deviceLanguage = "fr").language)
        assertEquals("es", WidgetInputs.fromValues(emptyMap<String, Any>(), deviceLanguage = "es").language)
        assertEquals("en", WidgetInputs.fromValues(emptyMap<String, Any>(), deviceLanguage = "it").language)
        assertEquals("en", WidgetInputs.fromValues(mapOf("language" to "en"), deviceLanguage = "de").language)
        assertEquals("de", WidgetInputs.fallbackLanguage("de"))
        assertEquals("en", WidgetInputs.fallbackLanguage("en"))
        assertEquals("fr", WidgetInputs.fallbackLanguage("fr"))
        assertEquals("es", WidgetInputs.fallbackLanguage("es"))
        assertEquals("en", WidgetInputs.fallbackLanguage("it"))
    }

    @Test
    fun `published French and Spanish are kept`() {
        assertEquals("fr", WidgetInputs.fromValues(mapOf("language" to "fr"), deviceLanguage = "de").language)
        assertEquals("es", WidgetInputs.fromValues(mapOf("language" to "es"), deviceLanguage = "en").language)
        assertEquals("de", WidgetInputs.fromValues(mapOf("language" to "it"), deviceLanguage = "de").language)
    }

    @Test
    fun `contract fingerprint ignores order and unrelated keys`() {
        val a = WidgetInputs.contractFingerprint(mapOf("birth_date" to "1990-03-15", "language" to "en"))
        val b = WidgetInputs.contractFingerprint(mapOf("language" to "en", "birth_date" to "1990-03-15", "other" to 1))
        val c = WidgetInputs.contractFingerprint(mapOf("birth_date" to "1990-03-15", "language" to "de"))
        assertEquals(a, b)
        assertNotEquals(a, c)
        assertNotEquals(a, WidgetInputs.contractFingerprint(mapOf("birth_date" to "1990-03-15")))
    }

    @Test
    fun `contractValues keeps only contract keys`() {
        val values = WidgetInputs.contractValues(
            mapOf("birth_date" to "1990-03-15", "life_expectancy_years" to 90, "flutter.unrelated" to true),
        )
        assertEquals(mapOf("birth_date" to "1990-03-15", "life_expectancy_years" to 90), values)
    }

    @Test
    fun `remaining follows the display mode`() {
        val calc = LifeCalculator(LocalDate.of(1990, 3, 15), 80, LocalDate.of(2026, 3, 15))
        assertEquals(calc.weeksRemaining, calc.remaining(WidgetInputs.DisplayMode.WEEKS))
        assertEquals(calc.monthsRemaining, calc.remaining(WidgetInputs.DisplayMode.MONTHS))
        assertEquals(44, calc.remaining(WidgetInputs.DisplayMode.YEARS))
        assertEquals(calc.daysRemaining, calc.remaining(WidgetInputs.DisplayMode.DAYS))
    }
}
