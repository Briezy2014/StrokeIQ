package com.swimiq.app.ui

import android.app.Application
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.swimiq.app.ui.components.LoadingScreen
import com.swimiq.app.ui.navigation.MainTab
import com.swimiq.app.ui.screens.auth.LoginScreen
import com.swimiq.app.ui.screens.charts.ChartsScreen
import com.swimiq.app.ui.screens.coach.CoachDashboardScreen
import com.swimiq.app.ui.screens.dashboard.DashboardScreen
import com.swimiq.app.ui.screens.goals.GoalsScreen
import com.swimiq.app.ui.screens.meets.MeetHubScreen
import com.swimiq.app.ui.screens.notifications.NotificationsScreen
import com.swimiq.app.ui.screens.passport.AthletePassportScreen
import com.swimiq.app.ui.screens.personalbests.PersonalBestsScreen
import com.swimiq.app.ui.screens.settings.SettingsScreen
import com.swimiq.app.ui.screens.standards.StandardsScreen
import com.swimiq.app.ui.screens.training.TrainingLogScreen
import com.swimiq.app.ui.viewmodel.AuthViewModel
import com.swimiq.app.ui.viewmodel.AuthViewModelFactory
import com.swimiq.app.ui.viewmodel.CoachViewModel
import com.swimiq.app.ui.viewmodel.CoachViewModelFactory
import com.swimiq.app.ui.viewmodel.SwimViewModel
import com.swimiq.app.ui.viewmodel.SwimViewModelFactory

@Composable
fun SwimIQApp() {
    val authViewModel: AuthViewModel = viewModel(factory = AuthViewModelFactory())
    val authState by authViewModel.uiState.collectAsState()

    when {
        authState.isLoading -> LoadingScreen("Checking session…")
        !authState.isAuthenticated -> LoginScreen(authViewModel)
        else -> MainApp(onSignedOut = authViewModel::checkSession)
    }
}

@Composable
private fun MainApp(onSignedOut: () -> Unit) {
    val application = LocalContext.current.applicationContext as Application
    val swimViewModel: SwimViewModel = viewModel(factory = SwimViewModelFactory(application))
    val coachViewModel: CoachViewModel = viewModel(factory = CoachViewModelFactory(application))
    val swimState by swimViewModel.uiState.collectAsState()
    val coachState by coachViewModel.uiState.collectAsState()
    val navController = rememberNavController()
    val snackbarHostState = remember { SnackbarHostState() }
    val currentRoute = navController
        .currentBackStackEntryAsState()
        .value
        ?.destination
        ?.route

    val tabs = MainTab.tabsForRole(swimState.userRole)

    LaunchedEffect(swimState.message, swimState.errorMessage) {
        swimState.message?.let {
            snackbarHostState.showSnackbar(it)
            swimViewModel.clearMessage()
        }
        swimState.errorMessage?.let {
            snackbarHostState.showSnackbar(it)
            swimViewModel.clearMessage()
        }
    }

    LaunchedEffect(coachState.message, coachState.errorMessage) {
        coachState.message?.let {
            snackbarHostState.showSnackbar(it)
            coachViewModel.clearMessage()
        }
        coachState.errorMessage?.let {
            snackbarHostState.showSnackbar(it)
            coachViewModel.clearMessage()
        }
    }

    LaunchedEffect(swimState.isCoach) {
        if (swimState.isCoach) {
            coachViewModel.refresh()
        }
    }

    if (swimState.isLoading) {
        LoadingScreen("Loading swimmer data…")
        return
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            NavigationBar {
                tabs.forEach { tab ->
                    NavigationBarItem(
                        selected = currentRoute == tab.route,
                        onClick = {
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(tab.icon, contentDescription = tab.title) },
                        label = { Text(tab.title) },
                    )
                }
            }
        },
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = MainTab.Dashboard.route,
            modifier = Modifier.padding(padding),
        ) {
            composable(MainTab.Dashboard.route) {
                DashboardScreen(state = swimState, contentPadding = padding)
            }
            composable(MainTab.PersonalBests.route) {
                PersonalBestsScreen(state = swimState, contentPadding = padding)
            }
            composable(MainTab.Training.route) {
                TrainingLogScreen(
                    state = swimState,
                    contentPadding = padding,
                    onAdd = swimViewModel::addRaceLog,
                    onDelete = swimViewModel::deleteRaceLog,
                )
            }
            composable(MainTab.Meets.route) {
                MeetHubScreen(
                    state = swimState,
                    contentPadding = padding,
                    heatNotes = swimState.heatNotes,
                    selectedPlannedMeetId = swimState.selectedPlannedMeetId,
                    onSelectPlannedMeet = swimViewModel::selectPlannedMeet,
                    onAddResult = swimViewModel::addMeetResult,
                    onDeleteResult = swimViewModel::deleteMeetResult,
                    onAddPlannedMeet = swimViewModel::addPlannedMeet,
                    onDeletePlannedMeet = swimViewModel::deletePlannedMeet,
                    onAddHeatNote = swimViewModel::addHeatNote,
                    onDeleteHeatNote = swimViewModel::deleteHeatNote,
                )
            }
            composable(MainTab.Standards.route) {
                StandardsScreen(state = swimState, contentPadding = padding)
            }
            composable(MainTab.Goals.route) {
                GoalsScreen(
                    state = swimState,
                    contentPadding = padding,
                    onAdd = swimViewModel::addGoal,
                    onDelete = swimViewModel::deleteGoal,
                )
            }
            composable(MainTab.Charts.route) {
                ChartsScreen(state = swimState, contentPadding = padding)
            }
            composable(MainTab.Passport.route) {
                AthletePassportScreen(
                    state = swimState,
                    contentPadding = padding,
                    onSave = swimViewModel::saveProfile,
                )
            }
            composable(MainTab.Coach.route) {
                CoachDashboardScreen(
                    state = coachState,
                    contentPadding = padding,
                    onCreateTeam = coachViewModel::createTeam,
                    onInvite = coachViewModel::inviteSwimmer,
                    onRemoveMember = coachViewModel::removeMember,
                    onImportCsv = coachViewModel::importCsv,
                )
            }
            composable(MainTab.Alerts.route) {
                NotificationsScreen(
                    notifications = swimState.notifications,
                    goals = swimState.goals,
                    contentPadding = padding,
                    onMarkAllRead = swimViewModel::markAllNotificationsRead,
                    onMarkRead = swimViewModel::markNotificationRead,
                )
            }
            composable(MainTab.Settings.route) {
                SettingsScreen(
                    state = swimState,
                    contentPadding = padding,
                    onRefresh = swimViewModel::refresh,
                    onSetRole = swimViewModel::setUserRole,
                    onSignOut = { swimViewModel.signOut(onSignedOut) },
                )
            }
        }
    }
}
