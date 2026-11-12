package lifetree.coach.memento_mori_life_in_weeks.widget

/**
 * Colours of the app's theme styles (Stoic / Warm) in light and dark, as ARGB ints, mirroring
 * lib/theme/app_color_schemes.dart and lib/theme/life_palette.dart (and Swift LifePalette).
 * Shared by the phone widget (WidgetPalette) and the Wear OS surfaces.
 */
object LifePalette {
    /** One fully resolved colour set (a style in one brightness). */
    data class Tones(
        val background: Int,
        val primary: Int,
        val secondary: Int,
        val track: Int,
        val accent: Int,
        val lived: Int,
        val remaining: Int,
        val current: Int,
    )

    val STOIC_LIGHT = Tones(
        background = 0xFFF4F1EA.toInt(), primary = 0xFF1C1B1A.toInt(), secondary = 0xFF5E5A53.toInt(),
        track = 0xFFE3DED3.toInt(), accent = 0xFFD4973A.toInt(),
        lived = 0xFF1F1E1C.toInt(), remaining = 0xFFE3DED3.toInt(), current = 0xFFD4973A.toInt(),
    )
    val STOIC_DARK = Tones(
        background = 0xFF0F0F10.toInt(), primary = 0xFFF4F1EA.toInt(), secondary = 0xFFA9A49B.toInt(),
        track = 0xFF2A2A2D.toInt(), accent = 0xFFE0A84F.toInt(),
        lived = 0xFFA39D92.toInt(), remaining = 0xFF2A2A2D.toInt(), current = 0xFFE0A84F.toInt(),
    )
    val WARM_LIGHT = Tones(
        background = 0xFFFFF8F1.toInt(), primary = 0xFF2B2420.toInt(), secondary = 0xFF6B5B50.toInt(),
        track = 0xFFF2D9C6.toInt(), accent = 0xFFB4532A.toInt(),
        lived = 0xFFEFA27F.toInt(), remaining = 0xFFF2D9C6.toInt(), current = 0xFFB4532A.toInt(),
    )
    val WARM_DARK = Tones(
        background = 0xFF1E1714.toInt(), primary = 0xFFF6E9DF.toInt(), secondary = 0xFFD2BFB2.toInt(),
        track = 0xFF3F332C.toInt(), accent = 0xFFFFB591.toInt(),
        lived = 0xFFE6936E.toInt(), remaining = 0xFF3F332C.toInt(), current = 0xFFFFD08A.toInt(),
    )

    /**
     * Lived-cell colours the app publishes when no colour theme overrides the style
     * (life_palette.dart). Any other `color_lived` is a user-chosen colour theme.
     */
    val STYLE_DEFAULT_LIVED: Set<Int> = setOf(STOIC_LIGHT.lived, STOIC_DARK.lived, WARM_LIGHT.lived, WARM_DARK.lived)

    /** Lived and remaining cell colours in one brightness. */
    data class GridTones(val lived: Int, val remaining: Int)

    /**
     * Light and dark grid colours for [inputs]: a user colour theme (any `color_lived` that is
     * not a style default) uses the published colours, in dark mode the app's dark-adapted
     * `*_dark` variants (or the light ones if none were published); otherwise the style's.
     */
    fun gridTones(inputs: WidgetInputs): Pair<GridTones, GridTones> {
        val (light, dark) = tones(inputs.themeStyle)
        if (inputs.colorLived in STYLE_DEFAULT_LIVED) {
            return GridTones(light.lived, light.remaining) to GridTones(dark.lived, dark.remaining)
        }
        return GridTones(inputs.colorLived, inputs.colorRemaining) to GridTones(
            inputs.colorLivedDark ?: inputs.colorLived,
            inputs.colorRemainingDark ?: inputs.colorRemaining,
        )
    }

    /**
     * Tones for the watches, which are dark-first (OLED): always the dark variant of the
     * selected style, whatever `brightness` says. A user colour theme only replaces the lived /
     * remaining / current colours with its dark-adapted `*_dark` variants; without them the
     * style's dark palette is used (light theme colours are not meant for a black screen).
     */
    fun watchTones(inputs: WidgetInputs): Tones {
        val dark = tones(inputs.themeStyle).second
        if (inputs.colorLived in STYLE_DEFAULT_LIVED) return dark
        val lived = inputs.colorLivedDark ?: return dark
        return dark.copy(
            lived = lived,
            remaining = inputs.colorRemainingDark ?: dark.remaining,
            current = inputs.colorAccentDark ?: dark.current,
        )
    }

    /** Light and dark tones of [style]. */
    fun tones(style: WidgetInputs.ThemeStyle): Pair<Tones, Tones> = when (style) {
        WidgetInputs.ThemeStyle.STOIC -> STOIC_LIGHT to STOIC_DARK
        WidgetInputs.ThemeStyle.WARM -> WARM_LIGHT to WARM_DARK
    }
}
