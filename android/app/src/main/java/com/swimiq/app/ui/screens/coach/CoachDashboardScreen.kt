package com.swimiq.app.ui.screens.coach

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.swimiq.app.ui.components.MetricCard
import com.swimiq.app.ui.components.SectionHeader
import com.swimiq.app.ui.theme.SwimNavy
import com.swimiq.app.ui.viewmodel.CoachUiState
import com.swimiq.app.util.CsvMeetImporter
import kotlin.math.roundToInt

@Composable
fun CoachDashboardScreen(
    state: CoachUiState,
    contentPadding: PaddingValues,
    onCreateTeam: (String, String?) -> Unit,
    onInvite: (String, String?) -> Unit,
    onRemoveMember: (String) -> Unit,
    onImportCsv: (String) -> Unit,
) {
    var showCreateTeam by remember { mutableStateOf(false) }
    var showInvite by remember { mutableStateOf(false) }
    var showCsvImport by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(contentPadding)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        SectionHeader("Coach Dashboard · Version 3")

        if (state.teams.isEmpty()) {
            Text(
                text = "Create your first team to manage swimmers and view team analytics.",
                color = SwimNavy.copy(alpha = 0.7f),
            )
            Button(onClick = { showCreateTeam = true }, modifier = Modifier.fillMaxWidth()) {
                Text("Create Team")
            }
        } else {
            state.selectedTeam?.let { team ->
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(team.name, fontWeight = FontWeight.Black, color = SwimNavy)
                        team.clubName?.let {
                            Text(it, color = SwimNavy.copy(alpha = 0.8f))
                        }
                    }
                }
            }

            MetricCard("Team Avg SwimIQ", state.averageScore.roundToInt().toString())
            MetricCard("Total Sessions", state.totalSessions.toString())
            MetricCard("7-Day Attendance", "${state.attendanceRate.roundToInt()}%")
            MetricCard("Active Swimmers", state.teamStats.size.toString())

            SectionHeader("Top Performers")
            if (state.topPerformers.isEmpty()) {
                Text("No active swimmers with sessions yet.", color = SwimNavy.copy(alpha = 0.7f))
            } else {
                state.topPerformers.forEach { swimmer ->
                    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Text(swimmer.displayLabel, fontWeight = FontWeight.Bold, color = SwimNavy)
                            Text(
                                "SwimIQ ${swimmer.swimIQScore} · ${swimmer.sessionCount} sessions · ${swimmer.recentSessionCount} this week",
                                color = SwimNavy.copy(alpha = 0.7f),
                            )
                        }
                    }
                }
            }

            SectionHeader("Roster")
            RowActions(
                onInvite = { showInvite = true },
                onImport = { showCsvImport = true },
            )

            if (state.members.isEmpty()) {
                Text("Invite swimmers by email to build your roster.", color = SwimNavy.copy(alpha = 0.7f))
            } else {
                state.members.forEach { member ->
                    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Text(
                                member.displayName ?: member.inviteEmail,
                                fontWeight = FontWeight.Bold,
                                color = SwimNavy,
                            )
                            Text(
                                "${member.inviteEmail} · ${member.status}",
                                color = SwimNavy.copy(alpha = 0.7f),
                            )
                            member.id?.let { id ->
                                TextButton(onClick = { onRemoveMember(id) }) {
                                    Text("Remove")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showCreateTeam) {
        CreateTeamDialog(
            onDismiss = { showCreateTeam = false },
            onCreate = { name, club ->
                onCreateTeam(name, club)
                showCreateTeam = false
            },
        )
    }

    if (showInvite) {
        InviteDialog(
            onDismiss = { showInvite = false },
            onInvite = { email, name ->
                onInvite(email, name)
                showInvite = false
            },
        )
    }

    if (showCsvImport) {
        CsvImportDialog(
            onDismiss = { showCsvImport = false },
            onImport = { text ->
                onImportCsv(text)
                showCsvImport = false
            },
        )
    }
}

@Composable
private fun RowActions(onInvite: () -> Unit, onImport: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Button(onClick = onInvite, modifier = Modifier.fillMaxWidth()) {
            Text("Invite Swimmer")
        }
        OutlinedButton(onClick = onImport, modifier = Modifier.fillMaxWidth()) {
            Text("Import Meet Results (CSV)")
        }
    }
}

@Composable
private fun CreateTeamDialog(onDismiss: () -> Unit, onCreate: (String, String?) -> Unit) {
    var name by remember { mutableStateOf("") }
    var club by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Create Team") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Team Name") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = club, onValueChange = { club = it }, label = { Text("Club Name") }, modifier = Modifier.fillMaxWidth())
            }
        },
        confirmButton = {
            TextButton(onClick = { onCreate(name, club.ifBlank { null }) }) { Text("Create") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

@Composable
private fun InviteDialog(onDismiss: () -> Unit, onInvite: (String, String?) -> Unit) {
    var email by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Invite Swimmer") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = email, onValueChange = { email = it }, label = { Text("Email") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Display Name") }, modifier = Modifier.fillMaxWidth())
            }
        },
        confirmButton = {
            TextButton(onClick = { onInvite(email, name.ifBlank { null }) }) { Text("Invite") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

@Composable
private fun CsvImportDialog(onDismiss: () -> Unit, onImport: (String) -> Unit) {
    var csv by remember { mutableStateOf(CsvMeetImporter.template()) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Import Meet Results") },
        text = {
            Column {
                Text(
                    "Format: swimmer_name, meet_name, meet_date, event, swim_time, course",
                    style = MaterialTheme.typography.bodySmall,
                    color = SwimNavy.copy(alpha = 0.7f),
                )
                OutlinedTextField(
                    value = csv,
                    onValueChange = { csv = it },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp),
                    minLines = 6,
                )
            }
        },
        confirmButton = {
            TextButton(onClick = { onImport(csv) }) { Text("Import") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}
