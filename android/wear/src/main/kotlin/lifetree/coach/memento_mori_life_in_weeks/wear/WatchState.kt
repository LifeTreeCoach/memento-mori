package lifetree.coach.memento_mori_life_in_weeks.wear

import lifetree.coach.memento_mori_life_in_weeks.widget.LifePalette
import lifetree.coach.memento_mori_life_in_weeks.widget.WidgetInputs
import java.time.LocalDate

/** Everything the watch surfaces show, computed from the phone's inputs with :lifecore. */
sealed interface WatchState {
    val language: String

    /** Colours of every watch surface: the dark variant of the phone's theme (LifePalette.watchTones). */
    val palette: LifePalette.Tones

    /** No birth date received yet: ask the user to open the phone app. */
    data class NeedsPhone(
        override val language: String,
        override val palette: LifePalette.Tones = LifePalette.STOIC_DARK,
    ) : WatchState

    data class Ready(
        override val language: String,
        val displayMode: WidgetInputs.DisplayMode,
        val weekNumber: Int,
        val totalWeeks: Int,
        /** Floor of the lived share, as shown everywhere ("45%"). */
        val percentLived: Int,
        /** Exact lived share 0..1 for rings and arcs. */
        val progress: Float,
        val remaining: Int,
        val yearsLived: Int,
        val totalYears: Int,
        override val palette: LifePalette.Tones = LifePalette.STOIC_DARK,
    ) : WatchState

    companion object {
        fun from(inputs: WidgetInputs, today: LocalDate = LocalDate.now()): WatchState {
            val palette = LifePalette.watchTones(inputs)
            val calc = inputs.calculator(today) ?: return NeedsPhone(inputs.language, palette)
            return Ready(
                language = inputs.language,
                displayMode = inputs.displayMode,
                weekNumber = calc.currentWeekNumber,
                totalWeeks = calc.totalWeeks,
                percentLived = calc.percentLived.toInt(),
                progress = (calc.percentLived / 100).toFloat(),
                remaining = calc.remaining(inputs.displayMode),
                yearsLived = calc.yearsLived,
                totalYears = calc.totalYears,
                palette = palette,
            )
        }
    }
}
