package lifetree.coach.memento_mori_life_in_weeks.wear

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.wear.tiles.TileService
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester
import lifetree.coach.memento_mori_life_in_weeks.wear.complication.LifeComplicationService
import lifetree.coach.memento_mori_life_in_weeks.wear.tile.LifeTileService
import lifetree.coach.memento_mori_life_in_weeks.widget.nextLocalMidnight
import java.time.Duration
import java.time.ZonedDateTime

/** Pushes new values to the Tile and complication and keeps a daily refresh after midnight. */
object WatchRefresh {
    const val ACTION_REFRESH = "lifetree.coach.memento_mori_life_in_weeks.wear.MIDNIGHT_REFRESH"
    private const val TAG = "MementoWear"

    fun refreshSurfaces(receiverOrAppContext: Context) {
        // A BroadcastReceiver's context may not bind services, which the Tile updater needs.
        val context = receiverOrAppContext.applicationContext
        try {
            TileService.getUpdater(context).requestUpdate(LifeTileService::class.java)
            ComplicationDataSourceUpdateRequester
                .create(context, ComponentName(context, LifeComplicationService::class.java))
                .requestUpdateAll()
        } catch (e: Exception) {
            log("Surface refresh failed", e)
        }
        scheduleMidnight(context)
    }

    /** Inexact alarm shortly after local midnight (no exact-alarm permission needed). */
    fun scheduleMidnight(context: Context) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val triggerAt = System.currentTimeMillis() + millisUntilNextMidnight(ZonedDateTime.now()) + 60_000
        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC, triggerAt, pendingIntent(context))
    }

    /** Time left until the next local midnight; used for the Tile freshness too. */
    fun millisUntilNextMidnight(now: ZonedDateTime): Long = Duration.between(now, nextLocalMidnight(now)).toMillis()

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MidnightRefreshReceiver::class.java).setAction(ACTION_REFRESH)
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    internal fun log(message: String, error: Throwable? = null) {
        if (error == null) Log.i(TAG, message) else Log.w(TAG, message, error)
    }
}

/** Midnight alarm plus reboot / clock / time-zone changes: redraw and re-arm. */
class MidnightRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WatchRefresh.refreshSurfaces(context)
        WatchRefresh.log("Surfaces refreshed (${intent.action})")
    }
}
