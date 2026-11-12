package lifetree.coach.memento_mori_life_in_weeks.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/** Registered in AndroidManifest.xml; home_widget's updateWidget targets this class. */
class LifeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<LifeWidget>() {
    override val glanceAppWidget = LifeWidget()

    /**
     * home_widget's updateWidget sends APPWIDGET_UPDATE after every input change, even with no
     * widget placed (onUpdate only runs when widgets exist), so watches are synced from here.
     * goAsync() keeps the process alive during the send; it is null when Glance's onUpdate
     * already took the pending result (Glance then keeps the process alive itself).
     */
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val pending: PendingResult? = goAsync()
            WearSync.publish(context, pending)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        MidnightRefresh.schedule(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        MidnightRefresh.schedule(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        MidnightRefresh.cancel(context)
    }
}
