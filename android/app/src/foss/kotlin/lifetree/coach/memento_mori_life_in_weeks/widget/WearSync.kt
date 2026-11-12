package lifetree.coach.memento_mori_life_in_weeks.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.util.Log

/**
 * The foss flavor's stand-in for the Play flavor's Wear OS sync (src/play/.../WearSync.kt):
 * F-Droid, direct APK and other stores ship without Google Play Services, so there is no
 * Wearable Data Layer to publish to. Same API; nothing is sent.
 */
object WearSync {
    private const val TAG = "WearSync"

    /** Logs that watch sync is unavailable; [pending] (from `goAsync()`) is finished at once. */
    @Suppress("UNUSED_PARAMETER")
    fun publish(context: Context, pending: BroadcastReceiver.PendingResult? = null) {
        Log.i(TAG, "Watch sync not available in this build")
        pending?.finish()
    }
}
