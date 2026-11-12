package lifetree.coach.memento_mori_life_in_weeks.widget

import java.text.NumberFormat
import java.time.ZonedDateTime
import java.util.Locale

/** Locale-aware integers in the app's language ("1,912" in English, "1.912" in German). */
class LocalizedNumbers(language: String) {
    private val numbers: NumberFormat = NumberFormat.getIntegerInstance(Locale.forLanguageTag(language))

    fun format(value: Int): String = numbers.format(value)
}

/** Start of the next local day after [now] (DST-aware); week numbers change only then. */
fun nextLocalMidnight(now: ZonedDateTime = ZonedDateTime.now()): ZonedDateTime =
    now.toLocalDate().plusDays(1).atStartOfDay(now.zone)
