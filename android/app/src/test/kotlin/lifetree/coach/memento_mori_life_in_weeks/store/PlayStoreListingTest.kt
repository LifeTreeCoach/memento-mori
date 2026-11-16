package lifetree.coach.memento_mori_life_in_weeks.store

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PlayStoreListingTest {
    private val pkg = "lifetree.coach.memento_mori_life_in_weeks"

    @Test
    fun opensOnlyTheOwnListing() {
        assertEquals("market://details?id=$pkg", PlayStoreListing.uriFor(pkg))
    }

    @Test
    fun ownListingOrNothingIsNotIgnored() {
        assertFalse(PlayStoreListing.isIgnored(null, pkg))
        assertFalse(PlayStoreListing.isIgnored("market://details?id=$pkg", pkg))
    }

    @Test
    fun anyOtherArgumentIsIgnored() {
        assertTrue(PlayStoreListing.isIgnored("market://details?id=com.example.other", pkg))
        assertTrue(PlayStoreListing.isIgnored("https://example.com/", pkg))
        assertTrue(PlayStoreListing.isIgnored("intent://evil#Intent;end", pkg))
        assertTrue(PlayStoreListing.isIgnored(42, pkg))
        assertTrue(PlayStoreListing.isIgnored(listOf("market://details?id=$pkg"), pkg))
    }
}
