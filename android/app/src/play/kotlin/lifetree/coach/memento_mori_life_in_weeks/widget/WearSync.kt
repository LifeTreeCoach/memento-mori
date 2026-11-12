package lifetree.coach.memento_mori_life_in_weeks.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.util.Log
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataMap
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit

/**
 * Forwards the widget contract inputs to Wear OS watches as the DataItem
 * [WidgetInputs.WEAR_DATA_PATH] (docs/widget-data-contract.md, "Watches"). Runs off the main
 * thread and never throws: phones without Play services or the Wear OS app simply skip the sync.
 * Unchanged inputs are not re-sent (DataItems persist and reach late-connecting watches anyway).
 */
object WearSync {
    private const val TAG = "WearSync"
    private const val TIMEOUT_SECONDS = 10L
    private const val STATE_PREFERENCES = "WearSyncState"
    private const val LAST_SENT_FINGERPRINT = "last_sent_fingerprint"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /** Publishes in the background; [pending] (from `goAsync()`) is finished when done. */
    fun publish(context: Context, pending: BroadcastReceiver.PendingResult? = null) {
        val appContext = context.applicationContext
        scope.launch {
            try {
                publishNow(appContext)
            } finally {
                pending?.finish()
            }
        }
    }

    private fun publishNow(context: Context) {
        try {
            val values = WidgetInputs.contractValues(
                context.getSharedPreferences(WidgetInputs.PREFERENCES, Context.MODE_PRIVATE).all,
            )
            val fingerprint = WidgetInputs.contractFingerprint(values)
            val state = context.getSharedPreferences(STATE_PREFERENCES, Context.MODE_PRIVATE)
            if (state.getString(LAST_SENT_FINGERPRINT, null) == fingerprint) {
                Log.i(TAG, "Inputs unchanged; skipping watch sync")
                return
            }
            if (GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) != ConnectionResult.SUCCESS) {
                Log.i(TAG, "Play services unavailable; skipping watch sync")
                return
            }
            // Throws (ApiException) when the Wearable API is unavailable, e.g. no Wear OS app.
            val nodes = Tasks.await(Wearable.getNodeClient(context).connectedNodes, TIMEOUT_SECONDS, TimeUnit.SECONDS)
            val request = PutDataMapRequest.create(WidgetInputs.WEAR_DATA_PATH).apply {
                values.forEach { (key, value) -> dataMap.put(key, value) }
                dataMap.putLong(WidgetInputs.UPDATED_AT, System.currentTimeMillis())
            }.asPutDataRequest().setUrgent()
            Tasks.await(Wearable.getDataClient(context).putDataItem(request), TIMEOUT_SECONDS, TimeUnit.SECONDS)
            state.edit().putString(LAST_SENT_FINGERPRINT, fingerprint).apply()
            // Data items are also delivered later to watches that connect after this call.
            Log.i(TAG, "Inputs published (${values.size} keys, ${nodes.size} connected watch(es))")
        } catch (e: Exception) {
            Log.i(TAG, "Watch sync skipped: ${e.cause?.message ?: e.message}")
        }
    }

    private fun DataMap.put(key: String, value: Any) {
        when (value) {
            is Int -> putInt(key, value)
            is Long -> putLong(key, value)
            is Boolean -> putBoolean(key, value)
            is Float -> putFloat(key, value)
            is Double -> putDouble(key, value)
            else -> putString(key, value.toString())
        }
    }
}
