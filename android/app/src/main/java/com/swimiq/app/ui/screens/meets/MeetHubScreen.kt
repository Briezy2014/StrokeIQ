package com.swimiq.app.ui.screens.meets

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.swimiq.app.data.model.MeetHeatNote
import com.swimiq.app.data.model.MeetResult
import com.swimiq.app.data.model.PlannedMeet
import com.swimiq.app.ui.components.SectionHeader
import com.swimiq.app.ui.theme.SwimNavy
import com.swimiq.app.ui.viewmodel.SwimUiState
import com.swimiq.app.util.SwimTimeUtils
import java.time.LocalDate

private val courses = listOf("SCY", "SCM", "LCM")

@Composable
fun MeetHubScreen(
    state: SwimUiState,
    contentPadding: PaddingValues,
    heatNotes: List<MeetHeatNote>,
    selectedPlannedMeetId: String?,
    onSelectPlannedMeet: (String?) -> Unit,
    onAddResult: (MeetResult) -> Unit,
    onDeleteResult: (String) -> Unit,
    onAddPlannedMeet: (PlannedMeet) -> Unit,
    onDeletePlannedMeet: (String) -> Unit,
    onAddHeatNote: (MeetHeatNote) -> Unit,
    onDeleteHeatNote: (String) -> Unit,
) {
    var tabIndex by remember { mutableIntStateOf(0) }
    val tabs = listOf("Planner", "Results")

    Column(modifier = Modifier.fillMaxSize().padding(contentPadding)) {
        TabRow(selectedTabIndex = tabIndex) {
            tabs.forEachIndexed { index, title ->
                Tab(
                    selected = tabIndex == index,
                    onClick = { tabIndex = index },
                    text = { Text(title) },
                )
            }
        }

        when (tabIndex) {
            0 -> MeetPlannerTab(
                state = state,
                heatNotes = heatNotes,
                selectedPlannedMeetId = selectedPlannedMeetId,
                onSelectPlannedMeet = onSelectPlannedMeet,
                onAddPlannedMeet = onAddPlannedMeet,
                onDeletePlannedMeet = onDeletePlannedMeet,
                onAddHeatNote = onAddHeatNote,
                onDeleteHeatNote = onDeleteHeatNote,
            )
            else -> MeetResultsTab(
                state = state,
                onAdd = onAddResult,
                onDelete = onDeleteResult,
            )
        }
    }
}

@Composable
private fun MeetPlannerTab(
    state: SwimUiState,
    heatNotes: List<MeetHeatNote>,
    selectedPlannedMeetId: String?,
    onSelectPlannedMeet: (String?) -> Unit,
    onAddPlannedMeet: (PlannedMeet) -> Unit,
    onDeletePlannedMeet: (String) -> Unit,
    onAddHeatNote: (MeetHeatNote) -> Unit,
    onDeleteHeatNote: (String) -> Unit,
) {
    var showAddMeet by remember { mutableStateOf(false) }
    var showAddNote by remember { mutableStateOf(false) }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = { showAddMeet = true }) {
                Icon(Icons.Default.Add, contentDescription = "Add planned meet")
            }
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(
                top = innerPadding.calculateTopPadding() + 8.dp,
                bottom = innerPadding.calculateBottomPadding() + 72.dp,
                start = 16.dp,
                end = 16.dp,
            ),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item { SectionHeader("Meet Calendar") }

            val upcoming = state.upcomingMeets
            val past = state.plannedMeets.filter { it.meetDate < LocalDate.now().toString() }

            if (upcoming.isEmpty() && past.isEmpty()) {
                item {
                    Text(
                        "No planned meets. Tap + to add your next meet.",
                        color = SwimNavy.copy(alpha = 0.7f),
                    )
                }
            }

            if (upcoming.isNotEmpty()) {
                item { Text("Upcoming", fontWeight = FontWeight.Bold, color = SwimNavy) }
                items(upcoming, key = { it.id ?: it.hashCode().toString() }) { meet ->
                    PlannedMeetCard(
                        meet = meet,
                        selected = meet.id == selectedPlannedMeetId,
                        onSelect = { onSelectPlannedMeet(meet.id) },
                        onDelete = { meet.id?.let(onDeletePlannedMeet) },
                    )
                }
            }

            item {
                SectionHeader("Heat Sheet Notes")
                if (selectedPlannedMeetId == null) {
                    Text("Select a meet to add heat/lane notes.", color = SwimNavy.copy(alpha = 0.7f))
                } else {
                    TextButton(onClick = { showAddNote = true }) { Text("Add heat note") }
                }
            }

            items(heatNotes, key = { it.id ?: it.hashCode().toString() }) { note ->
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text("${note.event} · Heat ${note.heatNumber ?: "—"} · Lane ${note.laneNumber ?: "—"}", fontWeight = FontWeight.Bold)
                        note.notes?.let { Text(it, color = SwimNavy.copy(alpha = 0.8f)) }
                        note.id?.let { id ->
                            IconButton(onClick = { onDeleteHeatNote(id) }) {
                                Icon(Icons.Default.Delete, contentDescription = "Delete note")
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAddMeet) {
        AddPlannedMeetDialog(
            onDismiss = { showAddMeet = false },
            onSave = { meet ->
                onAddPlannedMeet(meet)
                showAddMeet = false
            },
        )
    }

    if (showAddNote && selectedPlannedMeetId != null) {
        AddHeatNoteDialog(
            plannedMeetId = selectedPlannedMeetId,
            onDismiss = { showAddNote = false },
            onSave = { note ->
                onAddHeatNote(note)
                showAddNote = false
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PlannedMeetCard(
    meet: PlannedMeet,
    selected: Boolean,
    onSelect: () -> Unit,
    onDelete: () -> Unit,
) {
    Card(
        onClick = onSelect,
        colors = CardDefaults.cardColors(
            containerColor = if (selected) {
                MaterialTheme.colorScheme.primaryContainer
            } else {
                MaterialTheme.colorScheme.surface
            },
        ),
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(meet.meetName, fontWeight = FontWeight.Bold, color = SwimNavy)
            Text("${meet.meetDate}${meet.location?.let { " · $it" } ?: ""}", color = SwimNavy.copy(alpha = 0.7f))
            meet.notes?.let { Text(it, color = SwimNavy.copy(alpha = 0.7f)) }
            TextButton(onClick = onDelete) { Text("Delete") }
        }
    }
}

@Composable
private fun MeetResultsTab(
    state: SwimUiState,
    onAdd: (MeetResult) -> Unit,
    onDelete: (String) -> Unit,
) {
    MeetResultsScreen(
        state = state,
        contentPadding = PaddingValues(0.dp),
        onAdd = onAdd,
        onDelete = onDelete,
    )
}

@Composable
private fun AddPlannedMeetDialog(onDismiss: () -> Unit, onSave: (PlannedMeet) -> Unit) {
    var name by remember { mutableStateOf("") }
    var date by remember { mutableStateOf(LocalDate.now().toString()) }
    var location by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Planned Meet") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Meet Name") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = date, onValueChange = { date = it }, label = { Text("Date (YYYY-MM-DD)") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = location, onValueChange = { location = it }, label = { Text("Location") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = notes, onValueChange = { notes = it }, label = { Text("Notes") }, modifier = Modifier.fillMaxWidth())
            }
        },
        confirmButton = { TextButton(onClick = { onSave(PlannedMeet(meetName = name.trim(), meetDate = date, location = location.ifBlank { null }, notes = notes.ifBlank { null })) }) { Text("Save") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

@Composable
private fun AddHeatNoteDialog(plannedMeetId: String, onDismiss: () -> Unit, onSave: (MeetHeatNote) -> Unit) {
    var event by remember { mutableStateOf("") }
    var heat by remember { mutableStateOf("") }
    var lane by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Heat Sheet Note") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = event, onValueChange = { event = it }, label = { Text("Event") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = heat, onValueChange = { heat = it }, label = { Text("Heat #") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = lane, onValueChange = { lane = it }, label = { Text("Lane #") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = notes, onValueChange = { notes = it }, label = { Text("Notes") }, modifier = Modifier.fillMaxWidth())
            }
        },
        confirmButton = {
            TextButton(onClick = {
                onSave(
                    MeetHeatNote(
                        plannedMeetId = plannedMeetId,
                        event = event.trim(),
                        heatNumber = heat.toIntOrNull(),
                        laneNumber = lane.toIntOrNull(),
                        notes = notes.ifBlank { null },
                    ),
                )
            }) { Text("Save") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

// Keep original MeetResultsScreen for Results tab
@Composable
fun MeetResultsScreen(
    state: SwimUiState,
    contentPadding: PaddingValues,
    onAdd: (MeetResult) -> Unit,
    onDelete: (String) -> Unit,
) {
    var showDialog by remember { mutableStateOf(false) }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        floatingActionButton = {
            FloatingActionButton(onClick = { showDialog = true }) {
                Icon(Icons.Default.Add, contentDescription = "Add meet result")
            }
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(
                top = contentPadding.calculateTopPadding() + innerPadding.calculateTopPadding(),
                bottom = contentPadding.calculateBottomPadding() + innerPadding.calculateBottomPadding() + 72.dp,
                start = 16.dp,
                end = 16.dp,
            ),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item { SectionHeader("Meet Results") }

            if (state.meetResults.isEmpty()) {
                item {
                    Text(
                        text = "No meet results yet. Tap + to add one.",
                        color = SwimNavy.copy(alpha = 0.7f),
                    )
                }
            } else {
                items(state.meetResults, key = { it.id ?: it.hashCode().toString() }) { result ->
                    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text(
                                text = result.meetName,
                                fontWeight = FontWeight.Bold,
                                color = SwimNavy,
                            )
                            Text(
                                text = "${result.meetDate} · ${result.event} · ${result.course}",
                                color = SwimNavy.copy(alpha = 0.7f),
                            )
                            Text(
                                text = SwimTimeUtils.formatSeconds(result.swimTime),
                                fontWeight = FontWeight.Bold,
                                color = SwimNavy,
                            )
                            result.id?.let { id ->
                                IconButton(onClick = { onDelete(id) }) {
                                    Icon(Icons.Default.Delete, contentDescription = "Delete")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showDialog) {
        AddMeetResultDialog(
            onDismiss = { showDialog = false },
            onSave = { result ->
                onAdd(result)
                showDialog = false
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddMeetResultDialog(
    onDismiss: () -> Unit,
    onSave: (MeetResult) -> Unit,
) {
    var meetName by remember { mutableStateOf("") }
    var meetDate by remember { mutableStateOf(LocalDate.now().toString()) }
    var event by remember { mutableStateOf("") }
    var timeText by remember { mutableStateOf("") }
    var course by remember { mutableStateOf(courses.first()) }
    var error by remember { mutableStateOf<String?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Meet Result") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = meetName, onValueChange = { meetName = it }, label = { Text("Meet Name") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = meetDate, onValueChange = { meetDate = it }, label = { Text("Meet Date") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = event, onValueChange = { event = it }, label = { Text("Event") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = timeText, onValueChange = { timeText = it }, label = { Text("Result Time") }, modifier = Modifier.fillMaxWidth())
                CourseDropdown(course) { course = it }
                error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            }
        },
        confirmButton = {
            TextButton(onClick = {
                try {
                    if (meetName.isBlank() || event.isBlank()) throw IllegalArgumentException("Meet name and event required.")
                    onSave(MeetResult(meetName = meetName.trim(), meetDate = meetDate, event = event.trim(), swimTime = SwimTimeUtils.toSeconds(timeText), course = course))
                } catch (e: Exception) { error = e.message }
            }) { Text("Save") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CourseDropdown(selected: String, onSelected: (String) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = !expanded }) {
        OutlinedTextField(value = selected, onValueChange = {}, readOnly = true, label = { Text("Course") }, trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded) }, modifier = Modifier.menuAnchor().fillMaxWidth())
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            courses.forEach { option ->
                DropdownMenuItem(text = { Text(option) }, onClick = { onSelected(option); expanded = false })
            }
        }
    }
}
