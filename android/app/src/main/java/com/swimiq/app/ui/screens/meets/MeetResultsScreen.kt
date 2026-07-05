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
import com.swimiq.app.data.model.MeetResult
import com.swimiq.app.ui.components.SectionHeader
import com.swimiq.app.ui.theme.SwimNavy
import com.swimiq.app.ui.viewmodel.SwimUiState
import com.swimiq.app.util.SwimTimeUtils
import java.time.LocalDate

private val courses = listOf("SCY", "SCM", "LCM")

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
        AddMeetDialog(
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
private fun AddMeetDialog(
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
                OutlinedTextField(
                    value = meetName,
                    onValueChange = { meetName = it },
                    label = { Text("Meet Name") },
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = meetDate,
                    onValueChange = { meetDate = it },
                    label = { Text("Meet Date (YYYY-MM-DD)") },
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = event,
                    onValueChange = { event = it },
                    label = { Text("Event") },
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = timeText,
                    onValueChange = { timeText = it },
                    label = { Text("Result Time") },
                    modifier = Modifier.fillMaxWidth(),
                )
                CourseDropdown(course) { course = it }
                error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    try {
                        if (meetName.isBlank() || event.isBlank()) {
                            throw IllegalArgumentException("Meet name and event are required.")
                        }
                        onSave(
                            MeetResult(
                                meetName = meetName.trim(),
                                meetDate = meetDate,
                                event = event.trim(),
                                swimTime = SwimTimeUtils.toSeconds(timeText),
                                course = course,
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
private fun CourseDropdown(selected: String, onSelected: (String) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = !expanded },
    ) {
        OutlinedTextField(
            value = selected,
            onValueChange = {},
            readOnly = true,
            label = { Text("Course") },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded) },
            modifier = Modifier.menuAnchor().fillMaxWidth(),
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            courses.forEach { option ->
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
