package com.swimiq.app.ui.screens.notifications

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
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.swimiq.app.data.model.AppNotification
import com.swimiq.app.data.model.Goal
import com.swimiq.app.ui.components.SectionHeader
import com.swimiq.app.ui.theme.SwimNavy
import com.swimiq.app.util.CoachAnalytics
import com.swimiq.app.util.SwimTimeUtils

@Composable
fun NotificationsScreen(
    notifications: List<AppNotification>,
    goals: List<Goal>,
    contentPadding: PaddingValues,
    onMarkAllRead: () -> Unit,
    onMarkRead: (String) -> Unit,
) {
    val upcomingGoals = CoachAnalytics.upcomingGoalDeadlines(goals)

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = contentPadding,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        item {
            SectionHeader(
                title = "Notifications",
                modifier = Modifier.padding(horizontal = 16.dp),
            )
        }

        if (notifications.any { !it.read }) {
            item {
                OutlinedButton(
                    onClick = onMarkAllRead,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                ) {
                    Text("Mark all as read")
                }
            }
        }

        if (notifications.isEmpty() && upcomingGoals.isEmpty()) {
            item {
                Text(
                    text = "No notifications yet. PBs and goal deadlines will appear here.",
                    modifier = Modifier.padding(horizontal = 16.dp),
                    color = SwimNavy.copy(alpha = 0.7f),
                )
            }
        }

        if (upcomingGoals.isNotEmpty()) {
            item {
                SectionHeader(
                    title = "Upcoming Goal Deadlines",
                    modifier = Modifier.padding(horizontal = 16.dp),
                )
            }
            items(upcomingGoals, key = { it.id ?: "${it.event}-${it.targetDate}" }) { goal ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text(goal.event, fontWeight = FontWeight.Bold, color = SwimNavy)
                        Text(
                            "Target ${SwimTimeUtils.formatSeconds(goal.goalTime)} by ${goal.targetDate}",
                            color = SwimNavy.copy(alpha = 0.8f),
                        )
                    }
                }
            }
        }

        items(notifications, key = { it.id ?: it.hashCode().toString() }) { notification ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (notification.read) {
                        MaterialTheme.colorScheme.surface
                    } else {
                        MaterialTheme.colorScheme.primaryContainer
                    },
                ),
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text(notification.title, fontWeight = FontWeight.Bold, color = SwimNavy)
                    Text(notification.body, color = SwimNavy.copy(alpha = 0.8f))
                    notification.id?.let { id ->
                        if (!notification.read) {
                            OutlinedButton(onClick = { onMarkRead(id) }) {
                                Text("Mark read")
                            }
                        }
                    }
                }
            }
        }
    }
}
