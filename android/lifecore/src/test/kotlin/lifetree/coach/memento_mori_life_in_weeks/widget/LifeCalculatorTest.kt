package lifetree.coach.memento_mori_life_in_weeks.widget

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.File
import java.time.LocalDate

/** Runs the shared Dart/Kotlin vectors from test/fixtures/life_calculator_vectors.json. */
class LifeCalculatorTest {
    private fun loadCases(): List<JSONObject> {
        val path = System.getProperty("lifeCalculatorVectors")
            ?: "../../test/fixtures/life_calculator_vectors.json"
        val cases = JSONObject(File(path).readText()).getJSONArray("cases")
        return (0 until cases.length()).map { cases.getJSONObject(it) }
    }

    private fun calculatorFor(vector: JSONObject) = LifeCalculator(
        birthDate = LocalDate.parse(vector.getString("birth_date")),
        lifeExpectancyYears = vector.getInt("life_expectancy_years"),
        today = LocalDate.parse(vector.getString("today")),
    )

    private fun actualValues(c: LifeCalculator): Map<String, Double> = mapOf(
        "age_years" to c.ageYears,
        "days_lived" to c.daysLived,
        "weeks_lived" to c.weeksLived,
        "total_weeks" to c.totalWeeks,
        "weeks_remaining" to c.weeksRemaining,
        "current_week_number" to c.currentWeekNumber,
        "months_lived" to c.monthsLived,
        "total_months" to c.totalMonths,
        "months_remaining" to c.monthsRemaining,
        "years_lived" to c.yearsLived,
        "total_years" to c.totalYears,
        "years_remaining" to c.yearsRemaining,
        "days_remaining" to c.daysRemaining,
    ).mapValues { it.value.toDouble() } + ("percent_lived" to c.percentLived)

    @Test
    fun matchesSharedFixture() {
        val cases = loadCases()
        assert(cases.size >= 8) { "expected at least 8 vectors, got ${cases.size}" }
        for (vector in cases) {
            val actual = actualValues(calculatorFor(vector))
            val expected = vector.getJSONObject("expected")
            for (key in expected.keys()) {
                assertEquals("${vector.getString("name")}: $key", expected.getDouble(key), actual.getValue(key), 1e-4)
            }
        }
    }

    @Test
    fun defaultsToEightyYears() {
        val c = LifeCalculator(LocalDate.of(2000, 1, 1), today = LocalDate.of(2000, 1, 8))
        assertEquals(80, c.lifeExpectancyYears)
        assertEquals(2, c.currentWeekNumber)
    }

    @Test
    fun futureBirthDateClampsToZero() {
        val c = LifeCalculator(LocalDate.of(2030, 1, 1), today = LocalDate.of(2026, 1, 1))
        assertEquals(0, c.weeksLived)
        assertEquals(0, c.ageYears)
        assertEquals(0, c.monthsLived)
        assertEquals(0.0, c.percentLived, 0.0)
    }
}
