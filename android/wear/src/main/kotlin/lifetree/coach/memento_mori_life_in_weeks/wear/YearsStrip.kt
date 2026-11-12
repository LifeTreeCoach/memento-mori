package lifetree.coach.memento_mori_life_in_weeks.wear

/** One dot per year of life expectancy, laid out in rows of [COLUMNS]. */
class YearsStrip(private val yearsLived: Int, val totalYears: Int) {
    enum class Dot { LIVED, CURRENT, REMAINING }

    val rows: Int get() = (totalYears + COLUMNS - 1) / COLUMNS

    fun dot(index: Int): Dot = when {
        index < yearsLived -> Dot.LIVED
        index == yearsLived -> Dot.CURRENT
        else -> Dot.REMAINING
    }

    companion object {
        const val COLUMNS = 10
    }
}
