package lifetree.coach.memento_mori_life_in_weeks.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import kotlin.math.ceil
import kotlin.math.min

/**
 * Draws life grids into small bitmaps (Glance has no canvas).
 *
 * Each grid is returned as three ALPHA_8 masks (lived, current, remaining) that the
 * widget tints with day/night colours, so one render serves light and dark mode.
 */
object LifeGridRenderer {
    enum class Cell { LIVED, CURRENT, REMAINING }

    /** Same-sized masks; ticks are drawn into [lived]. */
    class Layers(val lived: Bitmap, val current: Bitmap, val remaining: Bitmap)

    /** Upper bound for either bitmap side, keeps RemoteViews payloads small. */
    const val MAX_SIDE_PX = 600

    private const val GAP_RATIO = 0.25f
    private const val MAX_CELL_ASPECT = 1.6f
    private const val TICK_COLUMNS = 2
    private const val YEARS_PER_TICK = 10

    /** Row counts the medium widget's year strip may wrap into (8 rows of 10 = decades). */
    private val STRIP_ROW_OPTIONS = listOf(1, 2, 4, 8)

    /**
     * One cell per year, wrapped into the row count (see [STRIP_ROW_OPTIONS]) that gives
     * the biggest cells in [widthPx] x [heightPx]: 2 x 40 when short, more rows when taller.
     */
    fun yearStrip(calc: LifeCalculator, widthPx: Float, heightPx: Float): Layers {
        val geometry = yearStripGeometry(calc.totalYears, widthPx, heightPx)
        return render(geometry) { col, row -> cellState(row * geometry.columns + col, calc.yearsLived) }
    }

    internal fun yearStripGeometry(years: Int, widthPx: Float, heightPx: Float): Geometry {
        val cells = years.coerceAtLeast(1)
        val scale = min(1f, MAX_SIDE_PX / maxOf(widthPx, heightPx, 1f))
        val width = (widthPx * scale).coerceAtLeast(1f)
        val height = (heightPx * scale).coerceAtLeast(1f)
        val rows = STRIP_ROW_OPTIONS.maxBy { squarePitch(cells, it, width, height) }
        val columns = ceil(cells / rows.toFloat()).toInt()
        val square = squarePitch(cells, rows, width, height)
        val pitchX = min(width / columns, square * MAX_CELL_ASPECT)
        return Geometry(columns, rows, pitchX, square, tickColumns = 0, cells = cells)
    }

    private fun squarePitch(cells: Int, rows: Int, width: Float, height: Float): Float =
        min(width / ceil(cells / rows.toFloat()), height / rows)

    /**
     * The app's week grid: one row per year, 52 weeks per row, with decade ticks on the
     * left. Sized to fill [widthPx] x [heightPx] (scaled down to [MAX_SIDE_PX]).
     */
    fun weekGrid(calc: LifeCalculator, widthPx: Float, heightPx: Float): Layers {
        val geometry = weekGridGeometry(calc.totalYears, widthPx, heightPx)
        return render(geometry) { col, row -> cellState(row * LifeCalculator.WEEKS_PER_YEAR + col, calc.weeksLived) }
    }

    /** Cell pitch that fills the area: square cells, widened up to [MAX_CELL_ASPECT] to use spare width. */
    internal fun weekGridGeometry(years: Int, widthPx: Float, heightPx: Float): Geometry {
        val rows = years.coerceAtLeast(1)
        val units = LifeCalculator.WEEKS_PER_YEAR + TICK_COLUMNS
        val scale = min(1f, MAX_SIDE_PX / maxOf(widthPx, heightPx, 1f))
        val width = (widthPx * scale).coerceAtLeast(units.toFloat())
        val height = (heightPx * scale).coerceAtLeast(rows.toFloat())
        val square = min(width / units, height / rows)
        val pitchX = min(width / units, square * MAX_CELL_ASPECT)
        return Geometry(LifeCalculator.WEEKS_PER_YEAR, rows, pitchX, square, TICK_COLUMNS)
    }

    /** [cells] may be fewer than columns x rows; the trailing slots stay empty. */
    internal class Geometry(
        val columns: Int,
        val rows: Int,
        val pitchX: Float,
        val pitchY: Float,
        val tickColumns: Int,
        val cells: Int = columns * rows,
    ) {
        val widthPx: Int get() = ((columns + tickColumns) * pitchX).toInt().coerceAtLeast(1)
        val heightPx: Int get() = (rows * pitchY).toInt().coerceAtLeast(1)
        val originX: Float get() = tickColumns * pitchX
    }

    private fun cellState(index: Int, livedCount: Int): Cell = when {
        index < livedCount -> Cell.LIVED
        index == livedCount -> Cell.CURRENT
        else -> Cell.REMAINING
    }

    private fun render(geometry: Geometry, stateAt: (col: Int, row: Int) -> Cell): Layers {
        val layers = Layers(mask(geometry), mask(geometry), mask(geometry))
        val canvases = mapOf(
            Cell.LIVED to Canvas(layers.lived),
            Cell.CURRENT to Canvas(layers.current),
            Cell.REMAINING to Canvas(layers.remaining),
        )
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val rect = RectF()
        val cellW = geometry.pitchX * (1 - GAP_RATIO)
        val cellH = geometry.pitchY * (1 - GAP_RATIO)
        val radius = min(cellW, cellH) / 3
        for (row in 0 until geometry.rows) {
            for (col in 0 until geometry.columns) {
                if (row * geometry.columns + col >= geometry.cells) break
                val left = geometry.originX + col * geometry.pitchX
                val top = row * geometry.pitchY
                rect.set(left, top, left + cellW, top + cellH)
                canvases.getValue(stateAt(col, row)).drawRoundRect(rect, radius, radius, paint)
            }
        }
        drawDecadeTicks(canvases.getValue(Cell.LIVED), geometry, paint)
        return layers
    }

    /** Short marks left of every tenth year row (age 10, 20, ...). */
    private fun drawDecadeTicks(canvas: Canvas, geometry: Geometry, paint: Paint) {
        if (geometry.tickColumns == 0) return
        val thickness = (geometry.pitchY * 0.3f).coerceAtLeast(1f)
        val right = geometry.originX - geometry.pitchX * 0.4f
        val left = right - geometry.pitchX
        for (row in YEARS_PER_TICK until geometry.rows step YEARS_PER_TICK) {
            val centerY = row * geometry.pitchY + geometry.pitchY * (1 - GAP_RATIO) / 2
            canvas.drawRect(left, centerY - thickness / 2, right, centerY + thickness / 2, paint)
        }
    }

    private fun mask(geometry: Geometry): Bitmap =
        Bitmap.createBitmap(geometry.widthPx, geometry.heightPx, Bitmap.Config.ALPHA_8)
}
