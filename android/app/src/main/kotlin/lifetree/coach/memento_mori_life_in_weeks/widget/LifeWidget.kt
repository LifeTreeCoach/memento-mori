package lifetree.coach.memento_mori_life_in_weeks.widget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ColumnScope
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.RowScope
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontFamily
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity
import lifetree.coach.memento_mori_life_in_weeks.MainActivity

/**
 * Native life-in-weeks widget. Reads only the INPUTS published by Flutter and
 * computes everything itself, so it stays correct without the app running.
 */
class LifeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    // Exact: LocalSize is the real widget size, so the large grid bitmap can fill it.
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { WidgetContent() }
    }

    companion object {
        val SMALL = DpSize(110.dp, 110.dp)
        val MEDIUM = DpSize(250.dp, 110.dp)
        val LARGE = DpSize(250.dp, 250.dp)

        /** Outer padding and the large layout's header block, used to size the grid bitmap. */
        val CONTENT_PADDING = 14.dp
        val LARGE_HEADER_HEIGHT = 82.dp

        /** Medium layout: header row plus the spacing/progress line around the year strip. */
        val MEDIUM_HEADER_HEIGHT = 58.dp
        val MEDIUM_GAP = 8.dp
        val PROGRESS_HEIGHT = 3.dp

        /**
         * Opened by a widget tap with home_widget's launch action, so Flutter's `HomeWidget`
         * click stream reports it and shows the Life tab (same URL as the iOS `widgetURL`).
         */
        val LAUNCH_URI: Uri = Uri.parse("mementomori://widget?homeWidget")

        /** Re-reads inputs and redraws every placed instance (e.g. at midnight). */
        suspend fun refreshAll(context: Context) {
            val widget = LifeWidget()
            GlanceAppWidgetManager(context).getGlanceIds(LifeWidget::class.java).forEach { id ->
                updateAppWidgetState(context, widget.stateDefinition, id) { it }
                widget.update(context, id)
            }
        }
    }
}

private class WidgetUi(
    val inputs: WidgetInputs,
    val palette: WidgetPalette,
    val strings: WidgetStrings,
)

@Composable
private fun WidgetContent() {
    val context = LocalContext.current
    val inputs = WidgetInputs.fromPreferences(currentState<HomeWidgetGlanceState>().preferences)
    val ui = WidgetUi(inputs, WidgetPalette.from(inputs), WidgetStrings(context, inputs.language))
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ui.palette.background)
            .cornerRadius(20.dp)
            .padding(LifeWidget.CONTENT_PADDING)
            .clickable(actionStartActivity<MainActivity>(context, LifeWidget.LAUNCH_URI)),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        val calc = inputs.calculator()
        if (calc == null) SetupContent(ui) else SizedContent(ui, calc)
    }
}

@Composable
private fun ColumnScope.SizedContent(ui: WidgetUi, calc: LifeCalculator) {
    val size = LocalSize.current
    when {
        size.width >= LifeWidget.LARGE.width && size.height >= LifeWidget.LARGE.height -> LargeContent(ui, calc)
        size.width >= LifeWidget.MEDIUM.width -> MediumContent(ui, calc)
        else -> SmallContent(ui, calc)
    }
}

@Composable
private fun SetupContent(ui: WidgetUi) {
    Label(ui.strings.appName, ui.palette.accent)
    Spacer(GlanceModifier.height(6.dp))
    Text(ui.strings.setupMessage, style = TextStyle(color = ui.palette.primary, fontSize = 14.sp))
}

@Composable
private fun SmallContent(ui: WidgetUi, calc: LifeCalculator) {
    Label(ui.strings.weekLabel, ui.palette.secondary)
    BigNumber(ui.strings.number(calc.currentWeekNumber), ui.palette.primary, 34.sp)
    Spacer(GlanceModifier.height(10.dp))
    LifeProgress(ui, calc)
    Spacer(GlanceModifier.height(6.dp))
    Caption(ui.strings.percent(calc), ui.palette.secondary)
}

@Composable
private fun ColumnScope.MediumContent(ui: WidgetUi, calc: LifeCalculator) {
    Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
        Column(GlanceModifier.defaultWeight()) {
            Label(ui.strings.weekLabel, ui.palette.secondary)
            BigNumber(ui.strings.number(calc.currentWeekNumber), ui.palette.primary, 34.sp)
        }
        HeaderCaptions(ui, calc)
    }
    Spacer(GlanceModifier.height(LifeWidget.MEDIUM_GAP))
    GridImage(ui, mediumStrip(calc), GlanceModifier.defaultWeight(), GlanceModifier.fillMaxSize())
    Spacer(GlanceModifier.height(LifeWidget.MEDIUM_GAP))
    LifeProgress(ui, calc)
}

@Composable
private fun ColumnScope.LargeContent(ui: WidgetUi, calc: LifeCalculator) {
    Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
        Column(GlanceModifier.defaultWeight()) {
            Label(ui.strings.weekLabel, ui.palette.secondary)
            BigNumber(ui.strings.number(calc.currentWeekNumber), ui.palette.primary, 30.sp)
            Caption(ui.strings.ofTotal(calc.totalWeeks), ui.palette.secondary)
        }
        HeaderCaptions(ui, calc)
    }
    Spacer(GlanceModifier.height(10.dp))
    GridImage(ui, largeGrid(calc), GlanceModifier.defaultWeight(), GlanceModifier.fillMaxSize())
}

/**
 * Right header column (remaining + percent lived). It shares the row width with the week number,
 * so longer French/Spanish phrasings wrap to a second line instead of squeezing the big number.
 */
@Composable
private fun RowScope.HeaderCaptions(ui: WidgetUi, calc: LifeCalculator) {
    Column(GlanceModifier.defaultWeight(), horizontalAlignment = Alignment.End) {
        Caption(ui.strings.remaining(calc, ui.inputs.displayMode), ui.palette.primary, maxLines = 2, textAlign = TextAlign.End)
        Caption(ui.strings.percentLived(calc), ui.palette.secondary, textAlign = TextAlign.End)
    }
}

/** Week grid sized to the space left below the header, in device pixels. */
@Composable
private fun largeGrid(calc: LifeCalculator): LifeGridRenderer.Layers {
    val size = LocalSize.current
    val density = LocalContext.current.resources.displayMetrics.density
    val width = (size.width - LifeWidget.CONTENT_PADDING * 2).value * density
    val height = (size.height - LifeWidget.CONTENT_PADDING * 2 - LifeWidget.LARGE_HEADER_HEIGHT).value * density
    // Re-render only when the grid can look different (size or lived weeks), not on every recomposition.
    return remember(calc.totalYears, calc.weeksLived, width, height) {
        LifeGridRenderer.weekGrid(calc, width, height)
    }
}

/** Year strip sized to the space between the medium header and the progress line. */
@Composable
private fun mediumStrip(calc: LifeCalculator): LifeGridRenderer.Layers {
    val size = LocalSize.current
    val density = LocalContext.current.resources.displayMetrics.density
    val width = size.width - LifeWidget.CONTENT_PADDING * 2
    val chrome = LifeWidget.MEDIUM_HEADER_HEIGHT + LifeWidget.MEDIUM_GAP * 2 + LifeWidget.PROGRESS_HEIGHT
    val height = size.height - LifeWidget.CONTENT_PADDING * 2 - chrome
    val widthPx = width.value * density
    val heightPx = height.value * density
    return remember(calc.totalYears, calc.yearsLived, widthPx, heightPx) {
        LifeGridRenderer.yearStrip(calc, widthPx, heightPx)
    }
}

@Composable
private fun LifeProgress(ui: WidgetUi, calc: LifeCalculator) {
    LinearProgressIndicator(
        progress = (calc.percentLived / 100).toFloat(),
        modifier = GlanceModifier.fillMaxWidth().height(LifeWidget.PROGRESS_HEIGHT),
        color = ui.palette.accent,
        backgroundColor = ui.palette.track,
    )
}

/** Stacks the grid's mask layers, each tinted with its (day/night) palette colour. */
@Composable
private fun GridImage(
    ui: WidgetUi,
    layers: LifeGridRenderer.Layers,
    modifier: GlanceModifier = GlanceModifier,
    layerModifier: GlanceModifier = GlanceModifier.fillMaxWidth(),
) {
    val grid = ui.palette.grid
    Box(modifier = modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        GridLayer(layers.remaining, grid.remaining, null, layerModifier)
        GridLayer(layers.lived, grid.lived, null, layerModifier)
        GridLayer(layers.current, grid.current, ui.strings.gridDescription, layerModifier)
    }
}

@Composable
private fun GridLayer(mask: android.graphics.Bitmap, color: ColorProvider, description: String?, modifier: GlanceModifier) {
    Image(
        provider = ImageProvider(mask),
        contentDescription = description,
        contentScale = ContentScale.Fit,
        colorFilter = ColorFilter.tint(color),
        modifier = modifier,
    )
}

@Composable
private fun Label(text: String, color: ColorProvider) {
    Text(
        text.uppercase(),
        style = TextStyle(color = color, fontSize = 11.sp, fontWeight = FontWeight.Medium),
    )
}

@Composable
private fun BigNumber(text: String, color: ColorProvider, size: TextUnit) {
    Text(
        text,
        maxLines = 1,
        style = TextStyle(color = color, fontSize = size, fontFamily = FontFamily.Serif),
    )
}

@Composable
private fun Caption(text: String, color: ColorProvider, maxLines: Int = 1, textAlign: TextAlign = TextAlign.Start) {
    Text(text, maxLines = maxLines, style = TextStyle(color = color, fontSize = 12.sp, textAlign = textAlign))
}
