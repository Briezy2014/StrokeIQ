package com.swimiq.app.ui.screens.goals

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
import com.swimiq.app.data.model.Goal
import com.swimiq.app.ui.components.SectionHeader
import com.swimiq.app.ui.theme.SwimNavy
import com.swimiq.app.ui.viewmodel.SwimUiState
import com.swimiq.app.util.SwimTimeUtils
import java.time.LocalDate

private val strokes = listOf("Freestyle", "Backstroke", "Breaststroke", "Butterfly", "IM")
private val courses = listOf("SCY", "SCM", "LCM")

@Composable
fun GoalsScreen(
    state: SwimUiState,
    contentPadding: PaddingValues,
    onAdd: (Goal) -> Unit,
    onDelete: (String) -> Unit,
) {
    var showDialog by remember { mutableStateOf(false) }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        floatingActionButton = {
            FloatingActionButton(onClick = { showDialog = true }) {
                Icon(Icons.Default.Add, contentDescription = "Add goal")
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
            item { SectionHeader("Goals") }

            if (state.goals.isEmpty()) {
                item {
                    Text(
                        text = "No goals yet. Tap + to set your first target.",
                        color = SwimNavy.copy(alpha = 0.7f),
                    )
                }
            } else {
                items(state.goals, key = { it.id ?: it.hashCode().toString() }) { goal ->
                    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text(
                                text = goal.event,
                                fontWeight = FontWeight.Bold,
                                color = SwimNavy,
                            )
                            Text(
                                text = "Target: ${SwimTimeUtils.formatSeconds(goal.goalTime)} · ${goal.course}",
                                color = SwimNavy.copy(alpha = 0.7f),
                            )
                            goal.targetDate?.let {
                                Text(text = "By $it", color = SwimNavy.copy(alpha = 0.7f))
                            }
                            goal.id?.let { id ->
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
        AddGoalDialog(
            onDismiss = { showDialog = false },
            onSave = { goal ->
                onAdd(goal)
                showDialog = false
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddGoalDialog(
    onDismiss: () -> Unit,
    onSave: (Goal) -> Unit,
) {
    var stroke by remember { mutableStateOf(strokes.first()) }
    var distance by remember { mutableStateOf("100") }
    var targetTime by remember { mutableStateOf("") }
    var course by remember { mutableStateOf(courses.first()) }
    var targetDate by remember { mutableStateOf(LocalDate.now().toString()) }
    var error by remember { mutableStateOf<String?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Goal") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                DropdownField("Stroke", stroke, strokes) { stroke = it }
                DropdownField("Course", course, courses) { course = it }
                OutlinedTextField(
                    value = distance,
                    onValueChange = { distance = it },
                    label = { Text("Distance") },
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = targetTime,
                    onValueChange = { targetTime = it },
                    label = { Text("Target Time") },
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = targetDate,
                    onValueChange = { targetDate = it },
                    label = { Text("Target Date (YYYY-MM-DD)") },
                    modifier = Modifier.fillMaxWidth(),
                )
                error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    try {
                        val dist = distance.toIntOrNull()
                            ?: throw IllegalArgumentException("Enter a valid distance.")
                        onSave(
                            Goal(
                                event = "$dist $stroke",
                                goalTime = SwimTimeUtils.toSeconds(targetTime),
                                course = course,
                                targetDate = targetDate,
                            ),
                        )
                    } catch (e: Exception) {
                        error = e.message
                    }
                },
            ) { Text("Save") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        },
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DropdownField(
    label: String,
    selected: String,
    options: List<String>,
    onSelected: (String) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = !expanded },
    ) {
        OutlinedTextField(
            value = selected,
            onValueChange = {},
            readOnly = true,
            label = { Text(label) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded) },
            modifier = Modifier.menuAnchor().fillMaxWidth(),
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            options.forEach { option ->
                DropdownMenuItem(
                    text = { Text(option) },
                    onClick = {
                        onSelected(option)
                        expanded = false
                    },
                )
            }
        }
    }
}
