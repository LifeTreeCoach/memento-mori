package lifetree.coach.memento_mori_life_in_weeks.widget

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetLaunchFlagTest {
    private val flag = WidgetLaunchFlag("widget.LAUNCH")

    @Test
    fun `a widget launch is reported once`() {
        flag.record("widget.LAUNCH")
        assertTrue(flag.consume())
        assertFalse(flag.consume())
    }

    @Test
    fun `other launches are not reported`() {
        flag.record("android.intent.action.MAIN")
        flag.record(null)
        assertFalse(flag.consume())
    }

    @Test
    fun `repeated taps before Flutter asks are reported once`() {
        flag.record("widget.LAUNCH")
        flag.record("widget.LAUNCH")
        assertTrue(flag.consume())
        assertFalse(flag.consume())
    }
}
