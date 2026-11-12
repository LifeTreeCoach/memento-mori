package lifetree.coach.memento_mori_life_in_weeks.contacts

import org.junit.Assert.assertEquals
import org.junit.Test

class ContactBirthdayTextsTest {
    @Test
    fun keepsTheFirstNonBlankTextPerContact() {
        val texts = firstBirthdayTexts(
            listOf(
                BirthdayTextRow(1, " 15.08.1992 "),
                BirthdayTextRow(2, null),
                BirthdayTextRow(2, "  "),
                BirthdayTextRow(2, "--07-14"),
                BirthdayTextRow(1, "1990-01-01"),
            ),
        )

        assertEquals(mapOf("1" to "15.08.1992", "2" to "--07-14"), texts)
    }

    @Test
    fun noRowsGiveAnEmptyMap() {
        assertEquals(emptyMap<String, String>(), firstBirthdayTexts(emptyList()))
    }
}
