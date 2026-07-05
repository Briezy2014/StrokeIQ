package com.swimiq.app.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SportsScore
import androidx.compose.material.icons.filled.Star
import androidx.compose.ui.graphics.vector.ImageVector
import com.swimiq.app.data.model.UserRole

sealed class MainTab(
    val route: String,
    val title: String,
    val icon: ImageVector,
) {
    data object Dashboard : MainTab("dashboard", "Home", Icons.Default.Dashboard)
    data object PersonalBests : MainTab("personal_bests", "PBs", Icons.Default.Star)
    data object Training : MainTab("training", "Train", Icons.Default.FitnessCenter)
    data object Goals : MainTab("goals", "Goals", Icons.Default.EmojiEvents)
    data object Meets : MainTab("meets", "Meets", Icons.Default.SportsScore)
    data object Charts : MainTab("charts", "Charts", Icons.Default.BarChart)
    data object Passport : MainTab("passport", "Passport", Icons.Default.Badge)
    data object Coach : MainTab("coach", "Coach", Icons.Default.Groups)
    data object Alerts : MainTab("alerts", "Alerts", Icons.Default.Notifications)
    data object Settings : MainTab("settings", "Settings", Icons.Default.Settings)

    companion object {
        val swimmerTabs = listOf(
            Dashboard,
            PersonalBests,
            Training,
            Goals,
            Meets,
            Charts,
            Passport,
            Alerts,
            Settings,
        )

        val coachTabs = listOf(
            Dashboard,
            Coach,
            Alerts,
            Settings,
        )

        fun tabsForRole(role: String): List<MainTab> {
            return if (role == UserRole.COACH) coachTabs else swimmerTabs
        }
    }
}
