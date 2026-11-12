package lifetree.coach.memento_mori_life_in_weeks.wear.tile

import androidx.concurrent.futures.ResolvableFuture
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.degrees
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.ListenableFuture
import lifetree.coach.memento_mori_life_in_weeks.wear.MainActivity
import lifetree.coach.memento_mori_life_in_weeks.wear.WatchInputsStore
import lifetree.coach.memento_mori_life_in_weeks.wear.WatchRefresh
import lifetree.coach.memento_mori_life_in_weeks.wear.WatchStrings
import lifetree.coach.memento_mori_life_in_weeks.widget.LifePalette
import java.time.ZonedDateTime

/** Tile: current week number, a progress arc and "45% lived"; tapping opens the app. */
class LifeTileService : TileService() {
    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> {
        val state = WatchInputsStore.state(this)
        val strings = WatchStrings(this, state.language)
        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            // Recompute when the week number may change (the next local midnight).
            .setFreshnessIntervalMillis(WatchRefresh.millisUntilNextMidnight(ZonedDateTime.now()) + 60_000)
            .setTileTimeline(TimelineBuilders.Timeline.fromLayoutElement(layout(TileContent.from(state), strings, state.palette)))
            .build()
        return immediate(tile)
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> =
        immediate(ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build())

    private fun layout(
        content: TileContent,
        strings: WatchStrings,
        palette: LifePalette.Tones,
    ): LayoutElementBuilders.LayoutElement {
        val root = LayoutElementBuilders.Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setModifiers(openAppModifier())
        when (content) {
            is TileContent.NeedsPhone -> root.addContent(text(strings.needsPhone, 14f, palette.primary, maxLines = 3))
            is TileContent.Progress -> {
                root.addContent(arc(360f, palette.track))
                root.addContent(arc(content.sweepDegrees, palette.accent))
                root.addContent(
                    LayoutElementBuilders.Column.Builder()
                        .addContent(text(strings.weekLabel.uppercase(), 13f, palette.secondary))
                        .addContent(text(content.weekNumber, 40f, palette.primary, bold = true))
                        .addContent(text(strings.percentLived(content.percentLived), 14f, palette.accent))
                        .build(),
                )
            }
        }
        return root.build()
    }

    private fun arc(sweepDegrees: Float, color: Int): LayoutElementBuilders.LayoutElement =
        LayoutElementBuilders.Arc.Builder()
            .setAnchorAngle(degrees(0f))
            .setAnchorType(LayoutElementBuilders.ARC_ANCHOR_START)
            .addContent(
                LayoutElementBuilders.ArcLine.Builder()
                    .setLength(degrees(sweepDegrees))
                    .setThickness(dp(ARC_THICKNESS_DP))
                    .setColor(argb(color))
                    .build(),
            )
            .build()

    private fun text(
        value: String,
        sizeSp: Float,
        color: Int,
        bold: Boolean = false,
        maxLines: Int = 1,
    ): LayoutElementBuilders.LayoutElement =
        LayoutElementBuilders.Text.Builder()
            .setText(value)
            .setMaxLines(maxLines)
            .setFontStyle(
                LayoutElementBuilders.FontStyle.Builder()
                    .setSize(sp(sizeSp))
                    .setColor(argb(color))
                    .setWeight(
                        if (bold) LayoutElementBuilders.FONT_WEIGHT_BOLD else LayoutElementBuilders.FONT_WEIGHT_NORMAL,
                    )
                    .build(),
            )
            .build()

    private fun openAppModifier(): ModifiersBuilders.Modifiers =
        ModifiersBuilders.Modifiers.Builder()
            .setClickable(
                ModifiersBuilders.Clickable.Builder()
                    .setId(CLICK_OPEN_APP)
                    .setOnClick(
                        ActionBuilders.LaunchAction.Builder()
                            .setAndroidActivity(
                                ActionBuilders.AndroidActivity.Builder()
                                    .setPackageName(packageName)
                                    .setClassName(MainActivity::class.java.name)
                                    .build(),
                            )
                            .build(),
                    )
                    .build(),
            )
            .build()

    private fun <T> immediate(value: T): ListenableFuture<T> = ResolvableFuture.create<T>().apply { set(value) }

    private companion object {
        const val RESOURCES_VERSION = "1"
        const val CLICK_OPEN_APP = "open_app"
        const val ARC_THICKNESS_DP = 8f
    }
}
