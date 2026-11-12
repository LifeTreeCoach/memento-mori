package lifetree.coach.memento_mori_life_in_weeks.widget

import android.content.Context
import android.content.res.Configuration
import lifetree.coach.memento_mori_life_in_weeks.R
import java.util.Locale

/** Widget texts in the language chosen in the app (not necessarily the system language). */
class WidgetStrings(context: Context, language: String) {
    private val localized: Context = localizedContext(context, Locale.forLanguageTag(language))
    private val numbers = LocalizedNumbers(language)

    fun number(value: Int): String = numbers.format(value)

    val weekLabel: String get() = localized.getString(R.string.widget_week_label)

    val appName: String get() = localized.getString(R.string.widget_name)

    val setupMessage: String get() = localized.getString(R.string.widget_setup_message)

    val gridDescription: String get() = localized.getString(R.string.widget_grid_description)

    fun weekNumber(calc: LifeCalculator): String =
        localized.getString(R.string.widget_week_number, number(calc.currentWeekNumber))

    fun ofTotal(total: Int): String = localized.getString(R.string.widget_of_total, number(total))

    /** Locale-correct percent: "40%" in English, "40 %" (no-break space) in German, French and Spanish. */
    fun percent(calc: LifeCalculator): String =
        localized.getString(R.string.widget_percent, calc.percentLived.toInt())

    fun percentLived(calc: LifeCalculator): String =
        localized.getString(R.string.widget_percent_lived, calc.percentLived.toInt())

    fun remaining(calc: LifeCalculator, mode: WidgetInputs.DisplayMode): String {
        val pluralRes = when (mode) {
            WidgetInputs.DisplayMode.WEEKS -> R.plurals.widget_weeks_left
            WidgetInputs.DisplayMode.MONTHS -> R.plurals.widget_months_left
            WidgetInputs.DisplayMode.YEARS -> R.plurals.widget_years_left
            WidgetInputs.DisplayMode.DAYS -> R.plurals.widget_days_left
        }
        val count = calc.remaining(mode)
        return localized.resources.getQuantityString(pluralRes, count, number(count))
    }

    private companion object {
        fun localizedContext(context: Context, locale: Locale): Context {
            val config = Configuration(context.resources.configuration)
            config.setLocale(locale)
            return context.createConfigurationContext(config)
        }
    }
}
