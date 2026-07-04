package com.swimiq.app.ui.screens.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.swimiq.app.data.model.SwimmerProfile
import com.swimiq.app.ui.theme.SwimBlue
import com.swimiq.app.ui.theme.SwimNavy
import com.swimiq.app.ui.viewmodel.SwimUiState

private val strokeOptions = listOf(
    "Freestyle",
    "Backstroke",
    "Breaststroke",
    "Butterfly",
    "IM",
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    state: SwimUiState,
    contentPadding: PaddingValues,
    onSave: (SwimmerProfile) -> Unit,
) {
    val profile = state.profile
    var firstName by remember(profile) { mutableStateOf(profile?.firstName.orEmpty()) }
    var lastName by remember(profile) { mutableStateOf(profile?.lastName.orEmpty()) }
    var preferredName by remember(profile) { mutableStateOf(profile?.preferredName.orEmpty()) }
    var birthday by remember(profile) { mutableStateOf(profile?.birthday.orEmpty()) }
    var graduationYear by remember(profile) {
        mutableStateOf(profile?.graduationYear?.toString().orEmpty())
    }
    var team by remember(profile) { mutableStateOf(profile?.team.orEmpty()) }
    var coach by remember(profile) { mutableStateOf(profile?.coachName.orEmpty()) }
    var primaryStroke by remember(profile) {
        mutableStateOf(profile?.primaryStroke ?: strokeOptions.first())
    }
    var secondaryStroke by remember(profile) {
        mutableStateOf(profile?.secondaryStroke ?: strokeOptions.first())
    }
    var favoriteEvent by remember(profile) { mutableStateOf(profile?.favoriteEvent.orEmpty()) }
    var usaId by remember(profile) { mutableStateOf(profile?.usaSwimmingId.orEmpty()) }
    var school by remember(profile) { mutableStateOf(profile?.school.orEmpty()) }
    var notes by remember(profile) { mutableStateOf(profile?.athleteNotes.orEmpty()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(contentPadding)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Card(
            colors = CardDefaults.cardColors(containerColor = SwimBlue),
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text(
                    text = "Athlete Passport",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.9f),
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = state.displayName.ifBlank { "Your Profile" },
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.onPrimary,
                    fontWeight = FontWeight.Black,
                )
                Text(
                    text = team.ifBlank { "Add your team" },
                    color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.9f),
                )
            }
        }

        OutlinedTextField(
            value = firstName,
            onValueChange = { firstName = it },
            label = { Text("First Name") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = lastName,
            onValueChange = { lastName = it },
            label = { Text("Last Name") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = preferredName,
            onValueChange = { preferredName = it },
            label = { Text("Preferred Name") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = birthday,
            onValueChange = { birthday = it },
            label = { Text("Birthday (YYYY-MM-DD)") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = graduationYear,
            onValueChange = { graduationYear = it },
            label = { Text("Graduation Year") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = team,
            onValueChange = { team = it },
            label = { Text("Club Team") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = coach,
            onValueChange = { coach = it },
            label = { Text("Coach") },
            modifier = Modifier.fillMaxWidth(),
        )

        StrokeDropdown("Primary Stroke", primaryStroke) { primaryStroke = it }
        StrokeDropdown("Secondary Stroke", secondaryStroke) { secondaryStroke = it }

        OutlinedTextField(
            value = favoriteEvent,
            onValueChange = { favoriteEvent = it },
            label = { Text("Favorite Event") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = usaId,
            onValueChange = { usaId = it },
            label = { Text("USA Swimming ID") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = school,
            onValueChange = { school = it },
            label = { Text("School") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = notes,
            onValueChange = { notes = it },
            label = { Text("Athlete Notes") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 3,
        )

        Button(
            onClick = {
                onSave(
                    SwimmerProfile(
                        id = profile?.id,
                        firstName = firstName.ifBlank { null },
                        lastName = lastName.ifBlank { null },
                        preferredName = preferredName.ifBlank { null },
                        birthday = birthday.ifBlank { null },
                        graduationYear = graduationYear.toIntOrNull(),
                        team = team.ifBlank { null },
                        coachName = coach.ifBlank { null },
                        primaryStroke = primaryStroke,
                        secondaryStroke = secondaryStroke,
                        favoriteEvent = favoriteEvent.ifBlank { null },
                        usaSwimmingId = usaId.ifBlank { null },
                        school = school.ifBlank { null },
                        athleteNotes = notes.ifBlank { null },
                        swimmerName = preferredName.ifBlank {
                            listOf(firstName, lastName).filter { it.isNotBlank() }.joinToString(" ")
                        },
                    ),
                )
            },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Save Profile")
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun StrokeDropdown(
    label: String,
    selected: String,
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
            modifier = Modifier
                .menuAnchor()
                .fillMaxWidth(),
        )
        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
        ) {
            strokeOptions.forEach { option ->
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
