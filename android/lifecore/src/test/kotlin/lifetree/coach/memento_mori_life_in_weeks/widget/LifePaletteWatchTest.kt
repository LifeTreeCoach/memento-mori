package lifetree.coach.memento_mori_life_in_weeks.widget

import org.junit.Assert.assertEquals
import org.junit.Test

/** Watch colours: always the dark variant of the style, user themes only via their `*_dark` keys. */
class LifePaletteWatchTest {
    private val ocean = mapOf("color_lived" to 0xFF1565C0L, "color_remaining" to 0xFFE3F2FDL)

    private fun watch(values: Map<String, Any>) = LifePalette.watchTones(WidgetInputs.fromValues(values))

    @Test
    fun `style palettes are always dark, whatever the brightness`() {
        assertEquals(LifePalette.STOIC_DARK, watch(emptyMap()))
        assertEquals(LifePalette.STOIC_DARK, watch(mapOf("theme_style" to "stoic", "brightness" to "light")))
        assertEquals(LifePalette.WARM_DARK, watch(mapOf("theme_style" to "warm", "brightness" to "light")))
        assertEquals(
            LifePalette.WARM_DARK,
            watch(mapOf("theme_style" to "warm", "brightness" to "system", "color_lived" to LifePalette.WARM_LIGHT.lived)),
        )
    }

    @Test
    fun `style palette ignores published dark colours`() {
        val values = mapOf("theme_style" to "warm", "color_lived" to LifePalette.WARM_LIGHT.lived, "color_lived_dark" to 1)
        assertEquals(LifePalette.WARM_DARK, watch(values))
    }

    @Test
    fun `user palette uses its dark variants on the style's dark background`() {
        val tones = watch(
            ocean + mapOf(
                "theme_style" to "warm",
                "color_lived_dark" to 0xFF5A8FD0L,
                "color_remaining_dark" to 0xFF1C2A3AL,
                "color_accent_dark" to 0xFFFFD08AL,
            ),
        )
        assertEquals(
            LifePalette.WARM_DARK.copy(
                lived = 0xFF5A8FD0L.toInt(),
                remaining = 0xFF1C2A3AL.toInt(),
                current = 0xFFFFD08AL.toInt(),
            ),
            tones,
        )
    }

    @Test
    fun `user palette without dark variants falls back to the style's dark palette`() {
        assertEquals(LifePalette.STOIC_DARK, watch(ocean))
        assertEquals(LifePalette.WARM_DARK, watch(ocean + ("theme_style" to "warm")))
    }

    @Test
    fun `missing remaining and accent dark keys keep the style's dark colours`() {
        val tones = watch(ocean + ("color_lived_dark" to 0xFF5A8FD0L))
        assertEquals(LifePalette.STOIC_DARK.copy(lived = 0xFF5A8FD0L.toInt()), tones)
    }
}
