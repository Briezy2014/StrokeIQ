package com.swimiq.app.ui.screens.dashboard

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.swimiq.app.ui.components.MetricCard
import com.swimiq.app.ui.components.SectionHeader
import com.swimiq.app.ui.theme.SwimBlueDark
import com.swimiq.app.ui.theme.SwimNavy
import com.swimiq.app.ui.viewmodel.SwimUiState
import com.swimiq.app.util.SwimAnalytics
import com.swimiq.app.util.SwimTimeUtils

@Composable
fun DashboardScreen(
    state: SwimUiState,
    contentPadding: PaddingValues,
) {
    val logs = state.raceLogs
    val breakdown = state.scoreBreakdown

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = contentPadding,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Column(modifier = Modifier.padding(horizontal = 16.dp)) {
                Text(
                    text = "Welcome, ${state.displayName}",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = SwimNavy,
                )
                Text(
                    text = "SwimIQ Dashboard · Version 3",
                    style = MaterialTheme.typography.bodyMedium,
                    color = SwimNavy.copy(alpha = 0.7f),
                )
                if (state.isFromCache) {
                    Text(
                        text = "Showing cached data",
                        style = MaterialTheme.typography.labelSmall,
                        color = SwimBlueDark,
                        modifier = Modifier.padding(top = 4.dp),
                    )
                }
            }
        }

        if (logs.isEmpty()) {
            item {
                Text(
                    text = "No swim sessions yet. Add a swim session to start building the dashboard.",
                    modifier = Modifier.padding(horizontal = 16.dp),
                    color = SwimNavy.copy(alpha = 0.7f),
                )
            }
        } else {
            item {
                Column(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    MetricCard("SwimIQ Score™", breakdown.totalScore.toString())
                    MetricCard("Total Sessions", logs.size.toString())
                    MetricCard("Personal Bests", state.personalBestCount.toString())
                    MetricCard("Active Goals", state.goals.size.toString())
                    MetricCard("Best Time", SwimAnalytics.bestTime(logs))
                    MetricCard("Average Time", SwimAnalytics.averageTime(logs))
                }
            }

            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer,
                    ),
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "How your SwimIQ Score works",
                            fontWeight = FontWeight.Bold,
                            color = SwimNavy,
                        )
                        breakdown.explanation.forEach { line ->
                            Text(
                                text = line,
                                color = SwimNavy.copy(alpha = 0.8f),
                                modifier = Modifier.padding(top = 4.dp),
                            )
                        }
                    }
                }
            }

            item {
                SectionHeader(
                    title = "Recent Sessions",
                    modifier = Modifier.padding(horizontal = 16.dp),
                )
            }

            items(logs.take(5)) { log ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface,
                    ),
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "${log.distance} ${log.stroke} · ${log.course}",
                            fontWeight = FontWeight.Bold,
                            color = SwimNavy,
                        )
                        Text(
                            text = "${log.date} · ${SwimTimeUtils.formatSeconds(log.timeSeconds)}",
                            color = SwimNavy.copy(alpha = 0.7f),
                        )
                    }
                }
            }
        }
    }
}
