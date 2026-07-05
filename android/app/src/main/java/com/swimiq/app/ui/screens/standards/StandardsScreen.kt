package com.swimiq.app.ui.screens.standards

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
import com.swimiq.app.ui.components.SectionHeader
import com.swimiq.app.ui.theme.SwimBlueDark
import com.swimiq.app.ui.theme.SwimNavy
import com.swimiq.app.ui.viewmodel.SwimUiState
import com.swimiq.app.util.SwimTimeUtils

@Composable
fun StandardsScreen(
    state: SwimUiState,
    contentPadding: PaddingValues,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = contentPadding,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        item {
            Column(modifier = Modifier.padding(horizontal = 16.dp)) {
                SectionHeader("USA Swimming Standards")
                Text(
                    text = "2024–2028 Motivational Age Group Standards (SCY)",
                    color = SwimNavy.copy(alpha = 0.7f),
                    style = MaterialTheme.typography.bodyMedium,
                )
                Text(
                    text = "Age group: ${state.standardsAgeGroup} · ${state.standardsCount} standards loaded",
                    color = SwimBlueDark,
                    style = MaterialTheme.typography.labelMedium,
                    modifier = Modifier.padding(top = 4.dp),
                )
            }
        }

        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Highest Cut Achieved", fontWeight = FontWeight.Bold, color = SwimNavy)
                    Text(
                        text = state.overallHighestCut,
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Black,
                        color = SwimNavy,
                    )
                }
            }
        }

        item {
            SectionHeader(
                title = "Personal Bests vs Cuts",
                modifier = Modifier.padding(horizontal = 16.dp),
            )
        }

        if (state.personalBestCuts.isEmpty()) {
            item {
                Text(
                    text = "Add swim sessions to compare your times against motivational cuts.",
                    modifier = Modifier.padding(horizontal = 16.dp),
                    color = SwimNavy.copy(alpha = 0.7f),
                )
            }
        } else {
            items(state.personalBestCuts, key = { "${it.stroke}-${it.distance}-${it.course}" }) { cut ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "${cut.distance} ${cut.stroke} · ${cut.course}",
                            fontWeight = FontWeight.Bold,
                            color = SwimNavy,
                        )
                        Text(
                            text = "Your PB: ${SwimTimeUtils.formatSeconds(cut.swimmerTime)}",
                            color = SwimNavy.copy(alpha = 0.8f),
                        )
                        Text(
                            text = "Highest cut: ${cut.highestCut ?: "None"}",
                            fontWeight = FontWeight.Bold,
                            color = SwimBlueDark,
                        )
                        Text(
                            text = cut.gap.gapLabel,
                            color = SwimNavy.copy(alpha = 0.7f),
                        )
                    }
                }
            }
        }
    }
}
