package com.swimiq.app.ui.viewmodel

import android.app.Application
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.swimiq.app.data.model.AppNotification
import com.swimiq.app.data.model.MeetResult
import com.swimiq.app.data.model.SwimmerTeamStats
import com.swimiq.app.data.model.Team
import com.swimiq.app.data.model.TeamMember
import com.swimiq.app.data.model.UserRole
import com.swimiq.app.data.repository.TeamRepository
import com.swimiq.app.notifications.SwimNotificationHelper
import com.swimiq.app.util.CoachAnalytics
import com.swimiq.app.util.CsvMeetImporter
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class CoachUiState(
    val isLoading: Boolean = true,
    val teams: List<Team> = emptyList(),
    val selectedTeam: Team? = null,
    val members: List<TeamMember> = emptyList(),
    val teamStats: List<SwimmerTeamStats> = emptyList(),
    val notifications: List<AppNotification> = emptyList(),
    val message: String? = null,
    val errorMessage: String? = null,
) {
    val averageScore: Double
        get() = CoachAnalytics.teamAverageScore(teamStats)

    val totalSessions: Int
        get() = CoachAnalytics.teamTotalSessions(teamStats)

    val attendanceRate: Double
        get() = CoachAnalytics.teamAttendanceRate(teamStats)

    val topPerformers: List<SwimmerTeamStats>
        get() = CoachAnalytics.topPerformers(teamStats)

    val unreadCount: Int
        get() = notifications.count { !it.read }
}

class CoachViewModel(
    private val teamRepository: TeamRepository = TeamRepository(),
    private val application: Application? = null,
) : ViewModel() {
    private val _uiState = MutableStateFlow(CoachUiState())
    val uiState: StateFlow<CoachUiState> = _uiState.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = it.teams.isEmpty(), errorMessage = null) }
            try {
                val teams = teamRepository.getTeams()
                val selected = _uiState.value.selectedTeam ?: teams.firstOrNull()
                val members = selected?.id?.let { teamRepository.getTeamMembers(it) } ?: emptyList()
                val stats = selected?.id?.let { teamRepository.loadTeamStats(it) } ?: emptyList()
                val notifications = teamRepository.getNotifications()

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        teams = teams,
                        selectedTeam = selected,
                        members = members,
                        teamStats = stats,
                        notifications = notifications,
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        errorMessage = e.message ?: "Failed to load coach data.",
                    )
                }
            }
        }
    }

    fun clearMessage() {
        _uiState.update { it.copy(message = null, errorMessage = null) }
    }

    fun selectTeam(team: Team) {
        viewModelScope.launch {
            _uiState.update { it.copy(selectedTeam = team, isLoading = true) }
            try {
                val members = teamRepository.getTeamMembers(team.id!!)
                val stats = teamRepository.loadTeamStats(team.id)
                _uiState.update {
                    it.copy(members = members, teamStats = stats, isLoading = false)
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, errorMessage = e.message)
                }
            }
        }
    }

    fun createTeam(name: String, clubName: String?) {
        if (name.isBlank()) {
            _uiState.update { it.copy(errorMessage = "Team name is required.") }
            return
        }
        viewModelScope.launch {
            try {
                teamRepository.createTeam(name, clubName)
                teamRepository.saveUserProfile(UserRole.COACH)
                refresh()
                _uiState.update { it.copy(message = "Team created.") }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun inviteSwimmer(email: String, displayName: String?) {
        val teamId = _uiState.value.selectedTeam?.id
        if (teamId == null) {
            _uiState.update { it.copy(errorMessage = "Create a team first.") }
            return
        }
        if (email.isBlank() || !email.contains("@")) {
            _uiState.update { it.copy(errorMessage = "Enter a valid email.") }
            return
        }
        viewModelScope.launch {
            try {
                teamRepository.inviteSwimmer(teamId, email, displayName)
                refresh()
                _uiState.update { it.copy(message = "Swimmer invited.") }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun removeMember(memberId: String) {
        viewModelScope.launch {
            try {
                teamRepository.removeMember(memberId)
                refresh()
                _uiState.update { it.copy(message = "Removed from roster.") }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun importCsv(csvText: String) {
        val teamId = _uiState.value.selectedTeam?.id
        if (teamId == null) {
            _uiState.update { it.copy(errorMessage = "Create a team first.") }
            return
        }
        viewModelScope.launch {
            try {
                val parsed = CsvMeetImporter.parse(csvText)
                if (parsed.imported.isEmpty()) {
                    _uiState.update {
                        it.copy(errorMessage = parsed.errors.firstOrNull() ?: "No rows imported.")
                    }
                    return@launch
                }
                val (count, errors) = teamRepository.bulkImportMeetResults(teamId, parsed.imported)
                refresh()
                val errorNote = if (errors.isNotEmpty()) " ${errors.size} skipped." else ""
                _uiState.update {
                    it.copy(message = "Imported $count meet results.$errorNote")
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun markAllNotificationsRead() {
        viewModelScope.launch {
            teamRepository.markAllNotificationsRead()
            refresh()
        }
    }

    fun markNotificationRead(id: String) {
        viewModelScope.launch {
            teamRepository.markNotificationRead(id)
            refresh()
        }
    }
}

class CoachViewModelFactory(
    private val application: Application,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(CoachViewModel::class.java)) {
            return CoachViewModel(application = application) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
