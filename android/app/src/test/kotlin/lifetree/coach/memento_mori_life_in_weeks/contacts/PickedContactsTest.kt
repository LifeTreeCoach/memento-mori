package lifetree.coach.memento_mori_life_in_weeks.contacts

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PickedContactsTest {
    private val photoBytes = byteArrayOf(1, 2, 3)

    private fun name(id: Long, name: String, lookup: String? = "lk$id") =
        PickedRow(id, lookup, name, PickedMimeTypes.STRUCTURED_NAME, name, null)

    private fun event(id: Long, date: String, type: Int = PickedMimeTypes.EVENT_TYPE_BIRTHDAY) =
        PickedRow(id, "lk$id", null, PickedMimeTypes.EVENT, date, type)

    private fun photo(id: Long) =
        PickedRow(id, "lk$id", null, PickedMimeTypes.PHOTO, null, null, photoBytes)

    @Test
    fun groupsRowsByContactInFirstSeenOrder() {
        val contacts = pickedContactsFromRows(
            listOf(name(2, "Bea"), event(1, "--07-14"), name(1, "Ada"), event(2, "1985-05-20"), photo(2)),
        )

        assertEquals(listOf("lk2", "lk1"), contacts.map { it.id })
        assertEquals(listOf("Bea", "Ada"), contacts.map { it.displayName })
        assertEquals(listOf("1985-05-20", "--07-14"), contacts.map { it.birthday })
        assertArrayEquals(photoBytes, contacts[0].thumbnail)
        assertNull(contacts[1].thumbnail)
    }

    @Test
    fun onlyTheFirstBirthdayEventCounts() {
        val contacts = pickedContactsFromRows(
            listOf(name(1, "Ada"), event(1, "2010-06-01", type = 1), event(1, "19900103"), event(1, "1991-01-01")),
        )

        assertEquals("19900103", contacts.single().birthday)
    }

    @Test
    fun contactWithoutBirthdayKeepsAnEmptyBirthdayAndNoPhoto() {
        val contact = pickedContactsFromRows(listOf(name(1, "Ada"), photo(1))).single()

        assertEquals("", contact.birthday)
        assertNull(contact.thumbnail)
    }

    @Test
    fun fallsBackToContactIdAndStructuredName() {
        val row = PickedRow(7, null, null, PickedMimeTypes.STRUCTURED_NAME, " Cleo ", null)
        val contact = pickedContactsFromRows(listOf(row, event(7, "--02-29"))).single()

        assertEquals("lk7", contact.id) // a later row's lookup key still applies
        assertEquals("Cleo", contact.displayName)
        val noKey = pickedContactsFromRows(listOf(row)).single()
        assertEquals("7", noKey.id)
    }

    @Test
    fun contactsWithoutAnyNameAreDropped() {
        val contacts = pickedContactsFromRows(listOf(event(1, "1985-05-20")))

        assertTrue(contacts.isEmpty())
    }

    @Test
    fun channelMapHasTheDartKeys() {
        val map = PickedContact("lk1", "Ada", "--07-14", null).toChannelMap()

        assertEquals(setOf("id", "displayName", "birthday", "thumbnail"), map.keys)
    }
}
