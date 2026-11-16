package lifetree.coach.memento_mori_life_in_weeks.reminders

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ScheduledAlarmProbeTest {
    @Test
    fun acceptsAnIntId() {
        assertEquals(100004, ScheduledAlarmProbe.idFrom(100004))
    }

    @Test
    fun rejectsEverythingElse() {
        assertNull(ScheduledAlarmProbe.idFrom(null))
        assertNull(ScheduledAlarmProbe.idFrom("100004"))
        assertNull(ScheduledAlarmProbe.idFrom(100004L))
        assertNull(ScheduledAlarmProbe.idFrom(mapOf("id" to 100004)))
    }
}
