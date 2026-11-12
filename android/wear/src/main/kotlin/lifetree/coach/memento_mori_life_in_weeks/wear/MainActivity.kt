package lifetree.coach.memento_mori_life_in_weeks.wear

import android.content.SharedPreferences
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import lifetree.coach.memento_mori_life_in_weeks.wear.sync.InputsSync
import lifetree.coach.memento_mori_life_in_weeks.widget.WidgetInputs

/** Single watch screen; recomputes when it comes to the front and when new inputs arrive. */
class MainActivity : ComponentActivity() {
    private val store by lazy { WatchInputsStore(this) }
    private var inputsListener: SharedPreferences.OnSharedPreferenceChangeListener? = null
    private var state by mutableStateOf<WatchState>(WatchState.NeedsPhone(WidgetInputs.fallbackLanguage()))

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        reload()
        setContent { WatchScreen(state) }
        InputsSync.pullLatest(this)
    }

    override fun onStart() {
        super.onStart()
        inputsListener = store.observe { reload() }
    }

    override fun onResume() {
        super.onResume()
        reload()
    }

    override fun onStop() {
        inputsListener?.let(store::unobserve)
        inputsListener = null
        super.onStop()
    }

    private fun reload() {
        state = WatchState.from(store.load())
    }
}
