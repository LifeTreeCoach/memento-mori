package lifetree.coach.memento_mori_life_in_weeks.widget

import android.content.Context
import android.content.SharedPreferences

/** Android readers for [WidgetInputs]; the pure model and decoding live in :lifecore. */
fun WidgetInputs.Companion.load(context: Context): WidgetInputs =
    fromPreferences(context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE))

fun WidgetInputs.Companion.fromPreferences(prefs: SharedPreferences): WidgetInputs = fromValues(prefs.all)
