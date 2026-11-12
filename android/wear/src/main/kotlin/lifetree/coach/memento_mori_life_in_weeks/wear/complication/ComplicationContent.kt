package lifetree.coach.memento_mori_life_in_weeks.wear.complication

import lifetree.coach.memento_mori_life_in_weeks.wear.WatchState
import lifetree.coach.memento_mori_life_in_weeks.widget.LifePalette

/** Complication values; pure so it is unit-tested without the complications library. */
data class ComplicationContent(
    /** Percent lived 0..100 for RANGED_VALUE. */
    val value: Float,
    /** Text inside the ranged value: the current week number, ungrouped to fit ("1912"). */
    val rangedText: String,
    /** SHORT_TEXT: localized week prefix + ungrouped week number ("W1912", "S1912" in French/Spanish). */
    val shortText: String,
    /**
     * Colour of the RANGED_VALUE arc (ColorRamp): the theme's dark accent. Only a hint - most
     * watch faces tint complications themselves.
     */
    val rangeColor: Int = LifePalette.STOIC_DARK.accent,
) {
    companion object {
        const val MIN = 0f
        const val MAX = 100f

        /**
         * Null when no inputs have been received yet. [weekPrefix] is the one-letter week
         * abbreviation in the synced language (string `complication_week_prefix`).
         */
        fun from(state: WatchState, weekPrefix: String): ComplicationContent? = when (state) {
            is WatchState.NeedsPhone -> null
            is WatchState.Ready -> ComplicationContent(
                value = (state.progress * MAX).coerceIn(MIN, MAX),
                rangedText = state.weekNumber.toString(),
                shortText = shortText(weekPrefix, state.weekNumber),
                rangeColor = state.palette.accent,
            )
        }

        /** "W1912": the prefix is joined without a space so it stays short on small slots. */
        fun shortText(weekPrefix: String, weekNumber: Int): String = "$weekPrefix$weekNumber"

        /** Sample values for the watch-face editor preview. */
        fun preview(weekPrefix: String): ComplicationContent =
            ComplicationContent(value = 45f, rangedText = "1912", shortText = shortText(weekPrefix, 1912))
    }
}
