package com.swimiq.app.ui.screens.personalbests

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
import com.swimiq.app.ui.theme.SwimNavy
import com.swimiq.app.ui.viewmodel.SwimUiState
import com.swimiq.app.util.SwimTimeUtils

@Composable
fun PersonalBestsScreen(
    state: SwimUiState,
    contentPadding: PaddingValues,
) {
    val personalBests = state.personalBests

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = contentPadding,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        item {
            SectionHeader(
                title = "Personal Bests",
                modifier = Modifier.padding(horizontal = 16.dp),
            )
        }

        if (personalBests.isEmpty()) {
            item {
                Text(
                    text = "No personal bests yet. Add swim sessions to unlock this page.",
                    modifier = Modifier.padding(horizontal = 16.dp),
                    color = SwimNavy.copy(alpha = 0.7f),
                )
            }
        } else {
            items(personalBests, key = { "${it.stroke}-${it.distance}-${it.course}" }) { log ->
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
                            text = "${log.distance} ${log.stroke}",
                            fontWeight = FontWeight.Bold,
                            color = SwimNavy,
                        )
                        Text(
                            text = "${log.course} · ${log.date}",
                            color = SwimNavy.copy(alpha = 0.7f),
                        )
                        Text(
                            text = SwimTimeUtils.formatSeconds(log.timeSeconds),
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Black,
                            color = SwimNavy,
                            modifier = Modifier.padding(top = 4.dp),
                        )
                    }
                }
            }
        }
    }
}
