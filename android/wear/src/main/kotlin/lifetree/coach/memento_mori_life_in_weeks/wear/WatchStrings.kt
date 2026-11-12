package lifetree.coach.memento_mori_life_in_weeks.wear

import android.content.Context
import android.content.res.Configuration
import lifetree.coach.memento_mori_life_in_weeks.widget.LocalizedNumbers
import lifetree.coach.memento_mori_life_in_weeks.widget.WidgetInputs
import java.util.Locale

/** Watch texts in the language chosen in the phone app (not necessarily the watch language). */
class WatchStrings(context: Context, language: String) {
    private val localized: Context = localizedContext(context, Locale.forLanguageTag(language))
    private val numbers = LocalizedNumbers(language)

    fun number(value: Int): String = numbers.format(value)

    val weekLabel: String get() = localized.getString(R.string.watch_week_label)

    val needsPhone: String get() = localized.getString(R.string.watch_needs_phone)

    val yearsTitle: String get() = localized.getString(R.string.watch_years_title)

    /** One-letter week abbreviation for the SHORT_TEXT complication ("W", "S" in French/Spanish). */
    val weekPrefix: String get() = localized.getString(R.string.complication_week_prefix)

    fun percent(percent: Int): String = localized.getString(R.string.watch_percent, percent)

    fun percentLived(percent: Int): String = localized.getString(R.string.watch_percent_lived, percent)

    fun remaining(state: WatchState.Ready): String {
        val pluralRes = when (state.displayMode) {
            WidgetInputs.DisplayMode.WEEKS -> R.plurals.watch_weeks_left
            WidgetInputs.DisplayMode.MONTHS -> R.plurals.watch_months_left
            WidgetInputs.DisplayMode.YEARS -> R.plurals.watch_years_left
            WidgetInputs.DisplayMode.DAYS -> R.plurals.watch_days_left
        }
        return localized.resources.getQuantityString(pluralRes, state.remaining, number(state.remaining))
    }

    private companion object {
        fun localizedContext(context: Context, locale: Locale): Context {
            val config = Configuration(context.resources.configuration)
            config.setLocale(locale)
            return context.createConfigurationContext(config)
        }
    }
}
