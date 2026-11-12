package lifetree.coach.memento_mori_life_in_weeks.widget

import java.time.LocalDate
import java.time.Year
import java.time.temporal.ChronoUnit

/**
 * Kotlin mirror of lib/core/life_calculator.dart. Both implementations are
 * pinned by test/fixtures/life_calculator_vectors.json — keep them in sync.
 * All calculations are date-only.
 */
class LifeCalculator(
    val birthDate: LocalDate,
    val lifeExpectancyYears: Int = DEFAULT_LIFE_EXPECTANCY_YEARS,
    val today: LocalDate = LocalDate.now(),
) {
    private val anniversaryReachedThisYear: Boolean
        get() = today.monthValue > birthDate.monthValue ||
            (today.monthValue == birthDate.monthValue && today.dayOfMonth >= birthDate.dayOfMonth)

    /** Full years of age (a Feb 29 birthday counts from Mar 1 in non-leap years). */
    val ageYears: Int
        get() = nonNegative(today.year - birthDate.year - if (anniversaryReachedThisYear) 0 else 1)

    val daysLived: Int
        get() = nonNegative(ChronoUnit.DAYS.between(birthDate, today).toInt())

    val weeksLived: Int get() = daysLived / 7

    val totalWeeks: Int get() = lifeExpectancyYears * WEEKS_PER_YEAR

    val weeksRemaining: Int get() = nonNegative(totalWeeks - weeksLived)

    /** 1-based number of the week currently being lived. */
    val currentWeekNumber: Int get() = weeksLived + 1

    /** Completed calendar months since birth. */
    val monthsLived: Int
        get() = nonNegative(
            (today.year - birthDate.year) * MONTHS_PER_YEAR +
                (today.monthValue - birthDate.monthValue) -
                if (today.dayOfMonth < birthDate.dayOfMonth) 1 else 0,
        )

    val totalMonths: Int get() = lifeExpectancyYears * MONTHS_PER_YEAR

    val monthsRemaining: Int get() = nonNegative(totalMonths - monthsLived)

    val yearsLived: Int get() = ageYears

    val totalYears: Int get() = lifeExpectancyYears

    val yearsRemaining: Int get() = nonNegative(totalYears - yearsLived)

    /** birthDate + lifeExpectancyYears; Feb 29 maps to Mar 1 in non-leap years. */
    val expectedEndDate: LocalDate
        get() {
            val year = birthDate.year + lifeExpectancyYears
            val isFeb29 = birthDate.monthValue == 2 && birthDate.dayOfMonth == 29
            return if (isFeb29 && !Year.isLeap(year.toLong())) {
                LocalDate.of(year, 3, 1)
            } else {
                LocalDate.of(year, birthDate.monthValue, birthDate.dayOfMonth)
            }
        }

    val daysRemaining: Int
        get() = nonNegative(ChronoUnit.DAYS.between(today, expectedEndDate).toInt())

    /** Share of [totalWeeks] already lived, 0..100. */
    val percentLived: Double
        get() = if (totalWeeks <= 0) 100.0 else (weeksLived.toDouble() / totalWeeks * 100).coerceIn(0.0, 100.0)

    /** Remaining time in the unit of [mode] (weeks / months / years / days left). */
    fun remaining(mode: WidgetInputs.DisplayMode): Int =
        when (mode) {
            WidgetInputs.DisplayMode.WEEKS -> weeksRemaining
            WidgetInputs.DisplayMode.MONTHS -> monthsRemaining
            WidgetInputs.DisplayMode.YEARS -> yearsRemaining
            WidgetInputs.DisplayMode.DAYS -> daysRemaining
        }

    private fun nonNegative(value: Int) = if (value < 0) 0 else value

    companion object {
        const val DEFAULT_LIFE_EXPECTANCY_YEARS = 80
        const val WEEKS_PER_YEAR = 52
        const val MONTHS_PER_YEAR = 12
    }
}
