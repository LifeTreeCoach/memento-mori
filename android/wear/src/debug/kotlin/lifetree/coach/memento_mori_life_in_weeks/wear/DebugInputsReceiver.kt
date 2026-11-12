package lifetree.coach.memento_mori_life_in_weeks.wear

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Debug-only: stores contract keys from intent extras as if the phone had sent them, e.g.
 * `adb shell am broadcast -a lifetree.coach.memento_mori_life_in_weeks.wear.DEBUG_INPUTS
 *  -p lifetree.coach.memento_mori_life_in_weeks --es birth_date 1990-03-15 --ei life_expectancy_years 80`.
 * Any contract key works with the matching extra type, e.g. `--es theme_style warm` or colours as
 * longs (`--el color_lived_dark 4284125136` = 0xFF5A8FD0). No extras clears the inputs (missing-data state).
 */
class DebugInputsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras
        @Suppress("DEPRECATION")
        val values = extras?.keySet()?.associateWith { extras.get(it) } ?: emptyMap()
        WatchInputsStore(context).save(values)
        WatchRefresh.log("Debug inputs stored: ${values.keys}")
        WatchRefresh.refreshSurfaces(context)
    }
}
