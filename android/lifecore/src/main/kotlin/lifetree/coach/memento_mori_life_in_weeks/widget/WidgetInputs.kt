package lifetree.coach.memento_mori_life_in_weeks.widget

import java.time.LocalDate
import java.time.format.DateTimeParseException
import java.util.Locale

/**
 * Inputs published by the Flutter app via home_widget (docs/widget-data-contract.md).
 * home_widget stores Dart ints as Int or Long depending on magnitude, so numbers are read as [Number].
 * Pure JVM: the Android SharedPreferences reader lives in :app (WidgetInputsStore.kt).
 */
data class WidgetInputs(
    val birthDate: LocalDate?,
    val lifeExpectancyYears: Int,
    val displayMode: DisplayMode,
    val language: String,
    val themeStyle: ThemeStyle,
    val brightness: Brightness,
    val colorLived: Int,
    val colorRemaining: Int,
    val colorAccent: Int,
    /** Dark-mode variants of a user colour theme (optional keys); null = use the light colour. */
    val colorLivedDark: Int? = null,
    val colorRemainingDark: Int? = null,
    val colorAccentDark: Int? = null,
) {
    enum class DisplayMode { WEEKS, MONTHS, YEARS, DAYS }

    enum class ThemeStyle { STOIC, WARM }

    enum class Brightness { SYSTEM, LIGHT, DARK }

    val isConfigured: Boolean get() = birthDate != null

    fun calculator(today: LocalDate = LocalDate.now()): LifeCalculator? =
        birthDate?.let { LifeCalculator(it, lifeExpectancyYears, today) }

    companion object {
        const val PREFERENCES = "HomeWidgetPreferences"
        const val DEFAULT_ACCENT = 0xFFE0A84F.toInt()

        /** Wear Data Layer path of the DataItem carrying the contract keys (contract "Watches"). */
        const val WEAR_DATA_PATH = "/memento/inputs"

        /** Extra DataItem key with the publish time, so watches can pick the newest item. */
        const val UPDATED_AT = "updated_at"

        val SUPPORTED_LANGUAGES: Set<String> = setOf("en", "de", "fr", "es")

        /** Every contract key; the phone forwards exactly these to watches (Wear Data Layer). */
        val CONTRACT_KEYS: List<String> = listOf(
            "schema_version",
            "birth_date",
            "life_expectancy_years",
            "widget_display_mode",
            "language",
            "theme_style",
            "brightness",
            "color_lived",
            "color_remaining",
            "color_accent",
            "color_lived_dark",
            "color_remaining_dark",
            "color_accent_dark",
        )

        /** Keeps only contract keys (e.g. from the shared home_widget preferences file). */
        fun contractValues(values: Map<String, *>): Map<String, Any> =
            CONTRACT_KEYS.mapNotNull { key -> values[key]?.let { key to it } }.toMap()

        /**
         * Stable text of the contract values in [values], used to skip re-sending unchanged inputs.
         * Equal for equal contract values regardless of map order or unrelated keys.
         */
        fun contractFingerprint(values: Map<String, *>): String =
            CONTRACT_KEYS.joinToString("\n") { key -> "$key=${values[key]}" }

        /** Language used when none was published: the device language if supported, English otherwise. */
        fun fallbackLanguage(deviceLanguage: String = Locale.getDefault().language): String =
            if (deviceLanguage in SUPPORTED_LANGUAGES) deviceLanguage else "en"

        /**
         * Decodes the contract keys from a raw key/value map (e.g. `SharedPreferences.all`).
         * [deviceLanguage] only matters when no supported `language` was published.
         */
        fun fromValues(values: Map<String, *>, deviceLanguage: String = Locale.getDefault().language): WidgetInputs =
            WidgetInputs(
                birthDate = parseDate(values["birth_date"] as? String),
                lifeExpectancyYears = readInt(values, "life_expectancy_years", LifeCalculator.DEFAULT_LIFE_EXPECTANCY_YEARS)
                    .takeIf { it > 0 } ?: LifeCalculator.DEFAULT_LIFE_EXPECTANCY_YEARS,
                displayMode = parseEnum(values["widget_display_mode"], DisplayMode.WEEKS),
                language = (values["language"] as? String)?.takeIf { it in SUPPORTED_LANGUAGES }
                    ?: fallbackLanguage(deviceLanguage),
                themeStyle = parseEnum(values["theme_style"], ThemeStyle.STOIC),
                brightness = parseEnum(values["brightness"], Brightness.SYSTEM),
                colorLived = readInt(values, "color_lived", 0xFF000000.toInt()),
                colorRemaining = readInt(values, "color_remaining", 0xFFFFFFFF.toInt()),
                colorAccent = readInt(values, "color_accent", DEFAULT_ACCENT),
                colorLivedDark = readOptionalInt(values, "color_lived_dark"),
                colorRemainingDark = readOptionalInt(values, "color_remaining_dark"),
                colorAccentDark = readOptionalInt(values, "color_accent_dark"),
            )

        private fun readInt(values: Map<String, *>, key: String, fallback: Int): Int =
            readOptionalInt(values, key) ?: fallback

        private fun readOptionalInt(values: Map<String, *>, key: String): Int? =
            when (val value = values[key]) {
                is Number -> value.toLong().toInt()
                is String -> value.toLongOrNull()?.toInt()
                else -> null
            }

        private fun parseDate(text: String?): LocalDate? {
            if (text.isNullOrBlank()) return null
            return try {
                LocalDate.parse(text.take(10))
            } catch (e: DateTimeParseException) {
                null
            }
        }

        /** Case-insensitive enum lookup by name (contract values are lowercase), else [fallback]. */
        private inline fun <reified T : Enum<T>> parseEnum(value: Any?, fallback: T): T =
            enumValues<T>().firstOrNull { it.name.equals(value as? String, ignoreCase = true) } ?: fallback
    }
}
