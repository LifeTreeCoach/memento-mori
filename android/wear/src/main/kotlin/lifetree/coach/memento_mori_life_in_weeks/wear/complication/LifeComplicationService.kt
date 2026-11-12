package lifetree.coach.memento_mori_life_in_weeks.wear.complication

import android.app.PendingIntent
import android.content.Intent
import androidx.wear.watchface.complications.data.ColorRamp
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationText
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.NoDataComplicationData
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.RangedValueComplicationData
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import lifetree.coach.memento_mori_life_in_weeks.wear.MainActivity
import lifetree.coach.memento_mori_life_in_weeks.wear.R
import lifetree.coach.memento_mori_life_in_weeks.wear.WatchInputsStore
import lifetree.coach.memento_mori_life_in_weeks.wear.WatchState
import lifetree.coach.memento_mori_life_in_weeks.wear.WatchStrings

/** RANGED_VALUE (percent lived, text = week number) and SHORT_TEXT ("W1912", "S1912") complications. */
class LifeComplicationService : SuspendingComplicationDataSourceService() {
    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? {
        val state = WatchInputsStore.state(this)
        val content = ComplicationContent.from(state, WatchStrings(this, state.language).weekPrefix)
            ?: return NoDataComplicationData()
        return build(request.complicationType, content, description(state), openApp())
    }

    /** Watch-face editor preview, in the watch's own language (no phone inputs involved). */
    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        val preview = ComplicationContent.preview(getString(R.string.complication_week_prefix))
        return build(type, preview, plain(preview.shortText), null)
    }

    private fun build(
        type: ComplicationType,
        content: ComplicationContent,
        description: ComplicationText,
        tapAction: PendingIntent?,
    ): ComplicationData? = when (type) {
        ComplicationType.RANGED_VALUE ->
            RangedValueComplicationData.Builder(content.value, ComplicationContent.MIN, ComplicationContent.MAX, description)
                .setText(plain(content.rangedText))
                .setColorRamp(ColorRamp(intArrayOf(content.rangeColor), false))
                .setTapAction(tapAction)
                .build()
        ComplicationType.SHORT_TEXT ->
            ShortTextComplicationData.Builder(plain(content.shortText), description)
                .setTapAction(tapAction)
                .build()
        else -> null
    }

    private fun description(state: WatchState): ComplicationText {
        val ready = state as? WatchState.Ready ?: return ComplicationText.EMPTY
        val strings = WatchStrings(this, state.language)
        return plain("${strings.weekLabel} ${strings.number(ready.weekNumber)}, ${strings.percentLived(ready.percentLived)}")
    }

    private fun openApp(): PendingIntent = PendingIntent.getActivity(
        this,
        0,
        Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun plain(text: String): ComplicationText = PlainComplicationText.Builder(text).build()
}
