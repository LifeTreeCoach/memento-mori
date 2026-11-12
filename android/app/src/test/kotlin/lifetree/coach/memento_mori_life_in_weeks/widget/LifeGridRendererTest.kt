package lifetree.coach.memento_mori_life_in_weeks.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Geometry of the widget grids (pure maths, no Bitmap needed). */
class LifeGridRendererTest {
    private val weeks = LifeCalculator.WEEKS_PER_YEAR

    @Test
    fun `years are rows and weeks are columns`() {
        val geometry = LifeGridRenderer.weekGridGeometry(years = 80, widthPx = 580f, heightPx = 400f)
        assertEquals(weeks, geometry.columns)
        assertEquals(80, geometry.rows)
    }

    @Test
    fun `grid stays within the area and the bitmap cap`() {
        val geometry = LifeGridRenderer.weekGridGeometry(years = 80, widthPx = 1400f, heightPx = 1800f)
        assertTrue(geometry.widthPx <= LifeGridRenderer.MAX_SIDE_PX)
        assertTrue(geometry.heightPx <= LifeGridRenderer.MAX_SIDE_PX)
    }

    @Test
    fun `short wide area widens cells but at most 1_6x`() {
        val geometry = LifeGridRenderer.weekGridGeometry(years = 80, widthPx = 600f, heightPx = 320f)
        assertEquals(4f, geometry.pitchY, 0.001f)
        assertEquals(6.4f, geometry.pitchX, 0.001f)
    }

    @Test
    fun `tall narrow area keeps square cells limited by width`() {
        val geometry = LifeGridRenderer.weekGridGeometry(years = 80, widthPx = 270f, heightPx = 600f)
        assertEquals(5f, geometry.pitchX, 0.001f)
        assertEquals(5f, geometry.pitchY, 0.001f)
    }

    @Test
    fun `grid fills the limiting dimension`() {
        val geometry = LifeGridRenderer.weekGridGeometry(years = 90, widthPx = 540f, heightPx = 450f)
        assertEquals(450, geometry.heightPx)
    }

    @Test
    fun `short medium strip wraps 80 years into 2 rows of 40`() {
        val geometry = LifeGridRenderer.yearStripGeometry(years = 80, widthPx = 580f, heightPx = 40f)
        assertEquals(2, geometry.rows)
        assertEquals(40, geometry.columns)
        assertEquals(80, geometry.cells)
    }

    @Test
    fun `taller medium strip wraps into 4 rows of 20`() {
        val geometry = LifeGridRenderer.yearStripGeometry(years = 80, widthPx = 580f, heightPx = 120f)
        assertEquals(4, geometry.rows)
        assertEquals(20, geometry.columns)
    }

    @Test
    fun `very tall medium strip becomes decade rows`() {
        val geometry = LifeGridRenderer.yearStripGeometry(years = 80, widthPx = 580f, heightPx = 400f)
        assertEquals(8, geometry.rows)
        assertEquals(10, geometry.columns)
    }

    @Test
    fun `uneven life expectancy leaves trailing slots empty`() {
        val geometry = LifeGridRenderer.yearStripGeometry(years = 90, widthPx = 580f, heightPx = 40f)
        assertEquals(2, geometry.rows)
        assertEquals(45, geometry.columns)
        assertEquals(90, geometry.cells)
    }

    @Test
    fun `strip fits inside the area and the bitmap cap`() {
        val geometry = LifeGridRenderer.yearStripGeometry(years = 80, widthPx = 900f, heightPx = 60f)
        assertTrue(geometry.widthPx <= LifeGridRenderer.MAX_SIDE_PX)
        assertTrue(geometry.heightPx <= 60)
    }

    @Test
    fun `degenerate area still yields a drawable strip`() {
        val geometry = LifeGridRenderer.yearStripGeometry(years = 80, widthPx = 0f, heightPx = -20f)
        assertTrue(geometry.widthPx >= 1)
        assertTrue(geometry.heightPx >= 1)
    }
}
