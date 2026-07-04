package com.swimiq.app.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SportsScore
import androidx.compose.ui.graphics.vector.ImageVector

sealed class MainTab(
    val route: String,
    val title: String,
    val icon: ImageVector,
) {
    data object Dashboard : MainTab("dashboard", "Dashboard", Icons.Default.Dashboard)
    data object Profile : MainTab("profile", "Profile", Icons.Default.Person)
    data object Training : MainTab("training", "Training", Icons.Default.FitnessCenter)
    data object Meets : MainTab("meets", "Meets", Icons.Default.SportsScore)
    data object Goals : MainTab("goals", "Goals", Icons.Default.EmojiEvents)
    data object Charts : MainTab("charts", "Charts", Icons.Default.BarChart)
    data object Settings : MainTab("settings", "Settings", Icons.Default.Settings)

    companion object {
        val tabs = listOf(Dashboard, Profile, Training, Meets, Goals, Charts, Settings)
    }
}
