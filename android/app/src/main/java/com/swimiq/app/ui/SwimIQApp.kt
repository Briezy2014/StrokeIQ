package com.swimiq.app.ui

import androidx.compose.foundation.layout.padding
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
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.swimiq.app.ui.components.LoadingScreen
import com.swimiq.app.ui.navigation.MainTab
import com.swimiq.app.ui.screens.auth.LoginScreen
import com.swimiq.app.ui.screens.charts.ChartsScreen
import com.swimiq.app.ui.screens.dashboard.DashboardScreen
import com.swimiq.app.ui.screens.goals.GoalsScreen
import com.swimiq.app.ui.screens.meets.MeetResultsScreen
import com.swimiq.app.ui.screens.profile.ProfileScreen
import com.swimiq.app.ui.screens.settings.SettingsScreen
import com.swimiq.app.ui.screens.training.TrainingLogScreen
import com.swimiq.app.ui.viewmodel.AuthViewModel
import com.swimiq.app.ui.viewmodel.AuthViewModelFactory
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
    val swimViewModel: SwimViewModel = viewModel(factory = SwimViewModelFactory())
    val swimState by swimViewModel.uiState.collectAsState()
    val navController = rememberNavController()
    val snackbarHostState = remember { SnackbarHostState() }
    val currentRoute = navController
        .currentBackStackEntryAsState()
        .value
        ?.destination
        ?.route

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

    if (swimState.isLoading) {
        LoadingScreen("Loading swimmer data…")
        return
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            NavigationBar {
                MainTab.tabs.forEach { tab ->
                    NavigationBarItem(
                        selected = currentRoute == tab.route,
                        onClick = {
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { androidx.compose.material3.Icon(tab.icon, contentDescription = tab.title) },
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
            composable(MainTab.Profile.route) {
                ProfileScreen(
                    state = swimState,
                    contentPadding = padding,
                    onSave = swimViewModel::saveProfile,
                )
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
                MeetResultsScreen(
                    state = swimState,
                    contentPadding = padding,
                    onAdd = swimViewModel::addMeetResult,
                    onDelete = swimViewModel::deleteMeetResult,
                )
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
            composable(MainTab.Settings.route) {
                SettingsScreen(
                    state = swimState,
                    contentPadding = padding,
                    onRefresh = swimViewModel::refresh,
                    onSignOut = { swimViewModel.signOut(onSignedOut) },
                )
            }
        }
    }
}
