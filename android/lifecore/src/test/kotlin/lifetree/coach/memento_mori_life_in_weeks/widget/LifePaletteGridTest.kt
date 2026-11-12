package lifetree.coach.memento_mori_life_in_weeks.widget

import org.junit.Assert.assertEquals
import org.junit.Test

/** Grid colours chosen from the published inputs (contract "color_*" keys). */
class LifePaletteGridTest {
    private val ocean = mapOf("color_lived" to 0xFF1565C0L, "color_remaining" to 0xFFE3F2FDL)

    private fun grid(values: Map<String, Any>) = LifePalette.gridTones(WidgetInputs.fromValues(values))

    @Test
    fun `style palette ignores published dark colours`() {
        val (light, dark) = grid(mapOf("theme_style" to "warm", "color_lived" to LifePalette.WARM_LIGHT.lived, "color_lived_dark" to 1))
        assertEquals(LifePalette.GridTones(LifePalette.WARM_LIGHT.lived, LifePalette.WARM_LIGHT.remaining), light)
        assertEquals(LifePalette.GridTones(LifePalette.WARM_DARK.lived, LifePalette.WARM_DARK.remaining), dark)
    }

    @Test
    fun `user palette uses the dark variants in dark mode`() {
        val (light, dark) = grid(ocean + mapOf("color_lived_dark" to 0xFF5A8FD0L, "color_remaining_dark" to 0xFF1C2A3AL))
        assertEquals(LifePalette.GridTones(0xFF1565C0L.toInt(), 0xFFE3F2FDL.toInt()), light)
        assertEquals(LifePalette.GridTones(0xFF5A8FD0L.toInt(), 0xFF1C2A3AL.toInt()), dark)
    }

    @Test
    fun `user palette without dark variants keeps the light colours`() {
        val (light, dark) = grid(ocean)
        assertEquals(light, dark)
        assertEquals(LifePalette.GridTones(0xFF1565C0L.toInt(), 0xFFE3F2FDL.toInt()), dark)
    }
}
