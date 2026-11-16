package lifetree.coach.memento_mori_life_in_weeks.reminders

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver

/**
 * Whether the alarm of a notification scheduled by flutter_local_notifications still exists.
 *
 * A "force stop" cancels the app's alarms and PendingIntents, but the plugin keeps its saved
 * pending list, so Flutter asks here (see `lib/reminders/lost_alarm_check.dart`).
 *
 * Mirrors the plugin's `getBroadcastPendingIntent` (FlutterLocalNotificationsPlugin.java,
 * v23): request code = notification id, explicit intent to [ScheduledNotificationReceiver]
 * without action, data or categories (extras are ignored by `Intent.filterEquals`), and
 * FLAG_IMMUTABLE, which is part of the PendingIntent key. FLAG_NO_CREATE only looks it up.
 */
class ScheduledAlarmProbe(private val context: Context) {
    fun hasScheduledAlarm(id: Int): Boolean {
        val intent = Intent(context, ScheduledNotificationReceiver::class.java)
        val flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(context, id, intent, flags) != null
    }

    companion object {
        /** The notification id in a method call's [arguments], or null unless it is an Int. */
        fun idFrom(arguments: Any?): Int? = arguments as? Int
    }
}
