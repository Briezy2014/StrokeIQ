package com.swimiq.app.ui.screens.charts

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.swimiq.app.ui.components.SectionHeader
import com.swimiq.app.ui.theme.SwimAccent
import com.swimiq.app.ui.theme.SwimBlue
import com.swimiq.app.ui.theme.SwimNavy
import com.swimiq.app.ui.viewmodel.SwimUiState
import com.swimiq.app.util.SwimTimeUtils

@Composable
fun ChartsScreen(
    state: SwimUiState,
    contentPadding: PaddingValues,
) {
    val logs = state.raceLogs.sortedBy { it.date }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(contentPadding)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        SectionHeader("Time Progress")

        if (logs.isEmpty()) {
            Text(
                text = "Add training sessions to see your progress chart.",
                color = SwimNavy.copy(alpha = 0.7f),
            )
        } else {
            val times = logs.map { it.timeSeconds.toFloat() }
            val minTime = times.minOrNull() ?: 0f
            val maxTime = times.maxOrNull() ?: 1f
            val range = (maxTime - minTime).coerceAtLeast(1f)

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "All Sessions (lower is faster)",
                        color = SwimNavy,
                        modifier = Modifier.padding(bottom = 8.dp),
                    )
                    Canvas(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(220.dp),
                    ) {
                        val width = size.width
                        val height = size.height
                        val stepX = if (times.size > 1) width / (times.size - 1) else width

                        val path = Path()
                        times.forEachIndexed { index, value ->
                            val x = if (times.size > 1) stepX * index else width / 2f
                            val normalized = 1f - ((value - minTime) / range)
                            val y = (normalized * (height * 0.8f)) + (height * 0.1f)
                            if (index == 0) {
                                path.moveTo(x, y)
                            } else {
                                path.lineTo(x, y)
                            }
                        }

                        drawLine(
                            color = SwimAccent.copy(alpha = 0.3f),
                            start = Offset(0f, height),
                            end = Offset(width, height),
                            strokeWidth = 2f,
                        )

                        drawPath(
                            path = path,
                            color = SwimBlue,
                            style = Stroke(width = 6f, cap = StrokeCap.Round),
                        )

                        times.forEachIndexed { index, value ->
                            val x = if (times.size > 1) stepX * index else width / 2f
                            val normalized = 1f - ((value - minTime) / range)
                            val y = (normalized * (height * 0.8f)) + (height * 0.1f)
                            drawCircle(
                                color = SwimBlue,
                                radius = 8f,
                                center = Offset(x, y),
                            )
                        }
                    }
                }
            }

            SectionHeader("Session History")
            logs.forEach { log ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text(
                            text = "${log.date} · ${log.distance} ${log.stroke}",
                            color = SwimNavy,
                        )
                        Text(
                            text = SwimTimeUtils.formatSeconds(log.timeSeconds),
                            color = SwimNavy.copy(alpha = 0.7f),
                        )
                    }
                }
            }
        }
    }
}
