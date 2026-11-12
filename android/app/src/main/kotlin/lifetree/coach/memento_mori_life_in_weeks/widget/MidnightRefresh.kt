package lifetree.coach.memento_mori_life_in_weeks.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.ZoneId
import java.time.ZonedDateTime

/** Inexact daily alarm shortly after local midnight so the week number ticks over. */
object MidnightRefresh {
    const val ACTION_REFRESH = "lifetree.coach.memento_mori_life_in_weeks.widget.MIDNIGHT_REFRESH"
    private const val TAG = "LifeWidget"

    fun schedule(context: Context) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC, nextMidnightMillis(), pendingIntent(context))
    }

    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java)?.cancel(pendingIntent(context))
    }

    fun hasWidgets(context: Context): Boolean {
        val component = ComponentName(context, LifeWidgetReceiver::class.java)
        return AppWidgetManager.getInstance(context).getAppWidgetIds(component).isNotEmpty()
    }

    internal fun nextMidnightMillis(zone: ZoneId = ZoneId.systemDefault()): Long =
        nextLocalMidnight(ZonedDateTime.now(zone)).plusMinutes(1).toInstant().toEpochMilli()

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

/** Handles the midnight alarm plus reboot / clock / time-zone changes. */
class MidnightRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!MidnightRefresh.hasWidgets(context)) {
            MidnightRefresh.cancel(context)
            return
        }
        val pending = goAsync()
        CoroutineScope(Dispatchers.Default).launch {
            try {
                LifeWidget.refreshAll(context)
                MidnightRefresh.log("Widget refreshed (${intent.action})")
            } catch (e: Exception) {
                MidnightRefresh.log("Widget refresh failed", e)
            } finally {
                MidnightRefresh.schedule(context)
                pending.finish()
            }
        }
    }
}
