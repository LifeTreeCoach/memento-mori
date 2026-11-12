package lifetree.coach.memento_mori_life_in_weeks.wear

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.material3.CircularProgressIndicator
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ProgressIndicatorDefaults
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import lifetree.coach.memento_mori_life_in_weeks.widget.LifePalette

/** Compose colours of the watch palette (always a dark style variant, see LifePalette.watchTones). */
private class WatchColors(tones: LifePalette.Tones) {
    val background = Color(tones.background)
    val primary = Color(tones.primary)
    val secondary = Color(tones.secondary)
    val track = Color(tones.track)
    val accent = Color(tones.accent)
    val lived = Color(tones.lived)
    val remaining = Color(tones.remaining)
    val current = Color(tones.current)
}

private val LocalWatchColors = staticCompositionLocalOf { WatchColors(LifePalette.STOIC_DARK) }

@Composable
fun WatchScreen(state: WatchState) {
    val strings = WatchStrings(LocalContext.current, state.language)
    val colors = remember(state.palette) { WatchColors(state.palette) }
    MaterialTheme {
        CompositionLocalProvider(LocalWatchColors provides colors) {
            AppScaffold(modifier = Modifier.fillMaxSize().background(colors.background)) {
                when (state) {
                    is WatchState.NeedsPhone -> NeedsPhone(strings)
                    is WatchState.Ready -> LifeOverview(state, strings)
                }
            }
        }
    }
}

@Composable
private fun NeedsPhone(strings: WatchStrings) {
    val colors = LocalWatchColors.current
    ScreenScaffold {
        Box(Modifier.fillMaxSize().padding(24.dp), contentAlignment = Alignment.Center) {
            Text(strings.needsPhone, color = colors.primary, textAlign = TextAlign.Center, fontSize = 15.sp)
        }
    }
}

@Composable
private fun LifeOverview(state: WatchState.Ready, strings: WatchStrings) {
    val colors = LocalWatchColors.current
    val listState = rememberTransformingLazyColumnState()
    ScreenScaffold(scrollState = listState) { contentPadding ->
        TransformingLazyColumn(state = listState, contentPadding = contentPadding, modifier = Modifier.fillMaxSize()) {
            item { WeekRing(state, strings) }
            item {
                Text(
                    strings.remaining(state),
                    color = colors.primary,
                    fontSize = 15.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                )
            }
            item {
                Text(
                    strings.yearsTitle,
                    color = colors.secondary,
                    fontSize = 12.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            item { YearsDots(YearsStrip(state.yearsLived, state.totalYears)) }
        }
    }
}

@Composable
private fun WeekRing(state: WatchState.Ready, strings: WatchStrings) {
    val colors = LocalWatchColors.current
    Box(Modifier.fillMaxWidth().aspectRatio(1f), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(
            progress = { state.progress },
            modifier = Modifier.fillMaxSize(),
            colors = ProgressIndicatorDefaults.colors(indicatorColor = colors.accent, trackColor = colors.track),
            strokeWidth = 8.dp,
        )
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            Text(strings.weekLabel.uppercase(), color = colors.secondary, fontSize = 13.sp, letterSpacing = 2.sp)
            Text(
                strings.number(state.weekNumber),
                color = colors.primary,
                fontSize = 44.sp,
                fontWeight = FontWeight.Bold,
            )
            Text(strings.percent(state.percentLived), color = colors.accent, fontSize = 16.sp)
        }
    }
}

@Composable
private fun YearsDots(strip: YearsStrip) {
    val colors = LocalWatchColors.current
    Canvas(
        Modifier
            .padding(vertical = 6.dp)
            .fillMaxWidth(0.7f)
            .aspectRatio(YearsStrip.COLUMNS.toFloat() / strip.rows),
    ) {
        val cell = size.width / YearsStrip.COLUMNS
        val radius = cell * 0.32f
        for (index in 0 until strip.totalYears) {
            val center = Offset(cell * (index % YearsStrip.COLUMNS + 0.5f), cell * (index / YearsStrip.COLUMNS + 0.5f))
            val color = when (strip.dot(index)) {
                YearsStrip.Dot.LIVED -> colors.lived
                YearsStrip.Dot.CURRENT -> colors.current
                YearsStrip.Dot.REMAINING -> colors.remaining
            }
            drawCircle(color, radius, center)
        }
    }
}
