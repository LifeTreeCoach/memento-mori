package lifetree.coach.memento_mori_life_in_weeks.wear.tile

import lifetree.coach.memento_mori_life_in_weeks.wear.WatchState
import lifetree.coach.memento_mori_life_in_weeks.widget.LocalizedNumbers

/** What the Tile shows; pure so it is unit-tested without ProtoLayout. */
sealed interface TileContent {
    data object NeedsPhone : TileContent

    data class Progress(
        val weekNumber: String,
        val percentLived: Int,
        /** Sweep of the progress arc, 0..360 degrees. */
        val sweepDegrees: Float,
    ) : TileContent

    companion object {
        fun from(state: WatchState): TileContent = when (state) {
            is WatchState.NeedsPhone -> NeedsPhone
            is WatchState.Ready -> Progress(
                weekNumber = LocalizedNumbers(state.language).format(state.weekNumber),
                percentLived = state.percentLived,
                sweepDegrees = (state.progress * FULL_CIRCLE).coerceIn(0f, FULL_CIRCLE),
            )
        }

        private const val FULL_CIRCLE = 360f
    }
}
