package lifetree.coach.memento_mori_life_in_weeks.wear.sync

import android.content.Context
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMap
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import lifetree.coach.memento_mori_life_in_weeks.wear.WatchInputsStore
import lifetree.coach.memento_mori_life_in_weeks.wear.WatchRefresh
import lifetree.coach.memento_mori_life_in_weeks.widget.WidgetInputs

/** Receives the phone's DataItem at [WidgetInputs.WEAR_DATA_PATH] (docs/widget-data-contract.md, "Watches"). */
class InputsListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        dataEvents
            .filter { it.type == DataEvent.TYPE_CHANGED && it.dataItem.uri.path == WidgetInputs.WEAR_DATA_PATH }
            .lastOrNull()
            ?.let { InputsSync.store(this, DataMapItem.fromDataItem(it.dataItem).dataMap) }
    }
}

object InputsSync {
    fun store(context: Context, dataMap: DataMap) {
        WatchInputsStore(context).save(dataMap.toValues())
        WatchRefresh.log("Inputs received from phone (${dataMap.keySet().size} keys)")
        WatchRefresh.refreshSurfaces(context)
    }

    /** Fetches the current DataItem, e.g. when the watch app was installed after the phone published. */
    fun pullLatest(context: Context) {
        val appContext = context.applicationContext
        Wearable.getDataClient(appContext).dataItems
            .addOnSuccessListener { items ->
                items.filter { it.uri.path == WidgetInputs.WEAR_DATA_PATH }
                    .maxByOrNull { DataMapItem.fromDataItem(it).dataMap.getLong(WidgetInputs.UPDATED_AT) }
                    ?.let { store(appContext, DataMapItem.fromDataItem(it).dataMap) }
                items.release()
            }
            .addOnFailureListener { WatchRefresh.log("Data Layer unavailable", it) }
    }

    private fun DataMap.toValues(): Map<String, Any?> = keySet().associateWith { key -> get<Any?>(key) }
}
