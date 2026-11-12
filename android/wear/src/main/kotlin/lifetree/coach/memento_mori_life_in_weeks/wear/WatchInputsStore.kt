package lifetree.coach.memento_mori_life_in_weeks.wear

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit
import lifetree.coach.memento_mori_life_in_weeks.widget.WidgetInputs

/** Last inputs received from the phone; the watch recomputes from them every day. */
class WatchInputsStore(context: Context) {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    /** Calls [onChange] whenever new inputs are stored; returns the handle to pass to [unobserve]. */
    fun observe(onChange: () -> Unit): SharedPreferences.OnSharedPreferenceChangeListener =
        SharedPreferences.OnSharedPreferenceChangeListener { _, _ -> onChange() }
            .also { prefs.registerOnSharedPreferenceChangeListener(it) }

    fun unobserve(listener: SharedPreferences.OnSharedPreferenceChangeListener) {
        prefs.unregisterOnSharedPreferenceChangeListener(listener)
    }

    fun load(): WidgetInputs = WidgetInputs.fromValues(prefs.all)

    /** Replaces the stored inputs with the contract keys of [values]; other keys are ignored. */
    fun save(values: Map<String, *>) {
        prefs.edit(commit = true) {
            clear()
            WidgetInputs.contractValues(values).forEach { (key, value) -> put(key, value) }
        }
    }

    private fun SharedPreferences.Editor.put(key: String, value: Any) {
        when (value) {
            is Int -> putInt(key, value)
            is Long -> putLong(key, value)
            is Boolean -> putBoolean(key, value)
            is Float -> putFloat(key, value)
            is Double -> putFloat(key, value.toFloat())
            else -> putString(key, value.toString())
        }
    }

    companion object {
        const val PREFERENCES = "WatchInputs"

        fun state(context: Context): WatchState = WatchState.from(WatchInputsStore(context).load())
    }
}
