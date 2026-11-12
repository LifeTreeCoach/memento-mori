package lifetree.coach.memento_mori_life_in_weeks.widget

import androidx.compose.ui.graphics.Color
import androidx.glance.color.ColorProvider
import androidx.glance.unit.ColorProvider

/**
 * Widget colours for the app's theme style and brightness; the colour values live in
 * :lifecore [LifePalette]. With [WidgetInputs.Brightness.SYSTEM] every colour is a day/night
 * pair, so the widget follows the launcher's dark mode without being redrawn.
 */
class WidgetPalette(
    val background: ColorProvider,
    val primary: ColorProvider,
    val secondary: ColorProvider,
    val track: ColorProvider,
    val accent: ColorProvider,
    val grid: GridColors,
) {
    /** Tints for the grid mask layers drawn by [LifeGridRenderer]. */
    class GridColors(val lived: ColorProvider, val remaining: ColorProvider, val current: ColorProvider)

    companion object {
        fun from(inputs: WidgetInputs): WidgetPalette {
            val (light, dark) = LifePalette.tones(inputs.themeStyle)
            val pick = { tone: (LifePalette.Tones) -> Int -> themed(inputs.brightness, tone(light), tone(dark)) }
            val (lightGrid, darkGrid) = LifePalette.gridTones(inputs)
            return WidgetPalette(
                background = pick { it.background },
                primary = pick { it.primary },
                secondary = pick { it.secondary },
                track = pick { it.track },
                accent = pick { it.accent },
                grid = GridColors(
                    lived = themed(inputs.brightness, lightGrid.lived, darkGrid.lived),
                    remaining = themed(inputs.brightness, lightGrid.remaining, darkGrid.remaining),
                    current = pick { it.current },
                ),
            )
        }

        private fun themed(brightness: WidgetInputs.Brightness, light: Int, dark: Int): ColorProvider = when (brightness) {
            WidgetInputs.Brightness.LIGHT -> ColorProvider(Color(light))
            WidgetInputs.Brightness.DARK -> ColorProvider(Color(dark))
            WidgetInputs.Brightness.SYSTEM -> ColorProvider(day = Color(light), night = Color(dark))
        }
    }
}
