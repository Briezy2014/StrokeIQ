package com.swimiq.app.ui.viewmodel

import android.app.Application
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.swimiq.app.data.local.CachedSwimData
import com.swimiq.app.data.local.SwimCache
import com.swimiq.app.data.model.AppNotification
import com.swimiq.app.data.model.Goal
import com.swimiq.app.data.model.MeetHeatNote
import com.swimiq.app.data.model.MeetResult
import com.swimiq.app.data.model.PersonalBestCut
import com.swimiq.app.data.model.PlannedMeet
import com.swimiq.app.data.model.RaceLog
import com.swimiq.app.data.model.SwimmerProfile
import com.swimiq.app.data.model.TimeStandard
import com.swimiq.app.data.model.UserRole
import com.swimiq.app.data.repository.MeetPlannerRepository
import com.swimiq.app.data.repository.SwimRepository
import com.swimiq.app.data.repository.TeamRepository
import com.swimiq.app.notifications.SwimNotificationHelper
import com.swimiq.app.util.StandardsService
import com.swimiq.app.util.SwimAnalytics
import com.swimiq.app.util.SwimIQScoreBreakdown
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class AuthUiState(
    val isLoading: Boolean = true,
    val isAuthenticated: Boolean = false,
    val email: String = "",
    val password: String = "",
    val isSignUp: Boolean = false,
    val errorMessage: String? = null,
)

data class SwimUiState(
    val isLoading: Boolean = true,
    val isRefreshing: Boolean = false,
    val isFromCache: Boolean = false,
    val profile: SwimmerProfile? = null,
    val raceLogs: List<RaceLog> = emptyList(),
    val goals: List<Goal> = emptyList(),
    val meetResults: List<MeetResult> = emptyList(),
    val notifications: List<AppNotification> = emptyList(),
    val userEmail: String? = null,
    val userRole: String = UserRole.SWIMMER,
    val standards: List<TimeStandard> = emptyList(),
    val plannedMeets: List<PlannedMeet> = emptyList(),
    val selectedPlannedMeetId: String? = null,
    val heatNotes: List<MeetHeatNote> = emptyList(),
    val message: String? = null,
    val errorMessage: String? = null,
) {
    val scoreBreakdown: SwimIQScoreBreakdown
        get() = SwimAnalytics.calculateSwimIQScore(raceLogs, goals)

    val swimIQScore: Int
        get() = scoreBreakdown.totalScore

    val personalBests: List<RaceLog>
        get() = SwimAnalytics.personalBests(raceLogs)

    val personalBestCount: Int
        get() = personalBests.size

    val displayName: String
        get() = profile?.preferredName
            ?: listOfNotNull(profile?.firstName, profile?.lastName)
                .joinToString(" ")
                .ifBlank { profile?.swimmerName.orEmpty() }
                .ifBlank { userEmail.orEmpty() }

    val readiness: String
        get() = SwimAnalytics.readiness(raceLogs, goals)

    val currentFocus: String
        get() = SwimAnalytics.currentFocus(profile)

    val nextMeet: String
        get() = SwimAnalytics.nextMeet(meetResults)

    val isCoach: Boolean
        get() = userRole == UserRole.COACH

    val unreadNotificationCount: Int
        get() = notifications.count { !it.read }

    val standardsAgeGroup: String
        get() = StandardsService.ageGroupFromProfile(profile)

    val standardsCount: Int
        get() = standards.size

    val personalBestCuts: List<PersonalBestCut>
        get() = StandardsService.personalBestCuts(standards, raceLogs, profile)

    val overallHighestCut: String
        get() = StandardsService.overallHighestCut(personalBestCuts)

    val upcomingMeets: List<PlannedMeet>
        get() = plannedMeets.filter { it.meetDate >= java.time.LocalDate.now().toString() }

    val nextPlannedMeet: String
        get() = upcomingMeets.firstOrNull()?.meetName ?: nextMeet
}

class AuthViewModel(
    private val repository: SwimRepository = SwimRepository(),
) : ViewModel() {
    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    init {
        checkSession()
    }

    fun checkSession() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            val loggedIn = repository.isLoggedIn()
            _uiState.update {
                it.copy(isLoading = false, isAuthenticated = loggedIn)
            }
        }
    }

    fun updateEmail(value: String) {
        _uiState.update { it.copy(email = value, errorMessage = null) }
    }

    fun updatePassword(value: String) {
        _uiState.update { it.copy(password = value, errorMessage = null) }
    }

    fun toggleSignUp() {
        _uiState.update { it.copy(isSignUp = !it.isSignUp, errorMessage = null) }
    }

    fun submit() {
        val state = _uiState.value
        if (state.email.isBlank() || state.password.length < 6) {
            _uiState.update {
                it.copy(errorMessage = "Enter a valid email and password (6+ characters).")
            }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            try {
                if (state.isSignUp) {
                    repository.signUp(state.email, state.password)
                } else {
                    repository.signIn(state.email, state.password)
                }
                _uiState.update {
                    it.copy(isLoading = false, isAuthenticated = true)
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        errorMessage = e.message ?: "Authentication failed.",
                    )
                }
            }
        }
    }
}

class SwimViewModel(
    private val repository: SwimRepository = SwimRepository(),
    private val teamRepository: TeamRepository = TeamRepository(),
    private val meetPlannerRepository: MeetPlannerRepository = MeetPlannerRepository(),
    private val cache: SwimCache? = null,
    private val application: Application? = null,
) : ViewModel() {
    private val _uiState = MutableStateFlow(SwimUiState())
    val uiState: StateFlow<SwimUiState> = _uiState.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            val userId = repository.currentUserId
            val cached = userId?.let { cache?.load(it) }

            if (cached != null && _uiState.value.raceLogs.isEmpty()) {
                applyData(
                    profile = cached.profile,
                    logs = cached.raceLogs,
                    goals = cached.goals,
                    meets = cached.meetResults,
                    isFromCache = true,
                    isLoading = true,
                )
            } else {
                _uiState.update {
                    it.copy(
                        isLoading = it.raceLogs.isEmpty(),
                        isRefreshing = it.raceLogs.isNotEmpty(),
                        errorMessage = null,
                    )
                }
            }

            try {
                teamRepository.acceptPendingInvites()
                val userProfile = teamRepository.getUserProfile()
                val profile = repository.getProfile()
                val logs = repository.getRaceLogs()
                val goals = repository.getGoals()
                val meets = repository.getMeetResults()
                val notifications = runCatching { teamRepository.getNotifications() }.getOrDefault(emptyList())
                val standards = application?.let { StandardsService.loadFromAssets(it) } ?: emptyList()
                val plannedMeets = runCatching { meetPlannerRepository.getPlannedMeets() }.getOrDefault(emptyList())
                val selectedMeetId = _uiState.value.selectedPlannedMeetId ?: plannedMeets.firstOrNull()?.id
                val heatNotes = if (selectedMeetId != null) {
                    runCatching { meetPlannerRepository.getHeatNotes(selectedMeetId) }.getOrDefault(emptyList())
                } else {
                    emptyList()
                }

                applyData(
                    profile = profile,
                    logs = logs,
                    goals = goals,
                    meets = meets,
                    notifications = notifications,
                    standards = standards,
                    plannedMeets = plannedMeets,
                    selectedPlannedMeetId = selectedMeetId,
                    heatNotes = heatNotes,
                    userRole = userProfile?.role ?: UserRole.SWIMMER,
                    isFromCache = false,
                    isLoading = false,
                    isRefreshing = false,
                )

                if (userId != null && cache != null) {
                    cache.save(
                        userId,
                        CachedSwimData(
                            profile = profile,
                            raceLogs = logs,
                            goals = goals,
                            meetResults = meets,
                        ),
                    )
                }
            } catch (e: Exception) {
                if (cached != null) {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            isRefreshing = false,
                            isFromCache = true,
                            errorMessage = "Showing cached data. ${e.message}",
                        )
                    }
                } else {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            isRefreshing = false,
                            errorMessage = e.message ?: "Failed to load data.",
                        )
                    }
                }
            }
        }
    }

    private fun applyData(
        profile: SwimmerProfile?,
        logs: List<RaceLog>,
        goals: List<Goal>,
        meets: List<MeetResult>,
        notifications: List<AppNotification> = _uiState.value.notifications,
        standards: List<TimeStandard> = _uiState.value.standards,
        plannedMeets: List<PlannedMeet> = _uiState.value.plannedMeets,
        selectedPlannedMeetId: String? = _uiState.value.selectedPlannedMeetId,
        heatNotes: List<MeetHeatNote> = _uiState.value.heatNotes,
        userRole: String = _uiState.value.userRole,
        isFromCache: Boolean,
        isLoading: Boolean,
        isRefreshing: Boolean = false,
    ) {
        _uiState.update {
            it.copy(
                isLoading = isLoading,
                isRefreshing = isRefreshing,
                isFromCache = isFromCache,
                profile = profile,
                raceLogs = logs,
                goals = goals,
                meetResults = meets,
                notifications = notifications,
                standards = standards,
                plannedMeets = plannedMeets,
                selectedPlannedMeetId = selectedPlannedMeetId,
                heatNotes = heatNotes,
                userEmail = repository.currentUserEmail,
                userRole = userRole,
            )
        }
    }

    fun setUserRole(role: String) {
        viewModelScope.launch {
            try {
                teamRepository.saveUserProfile(role)
                refresh()
                _uiState.update { it.copy(message = "Role updated to $role.") }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun clearMessage() {
        _uiState.update { it.copy(message = null, errorMessage = null) }
    }

    fun saveProfile(profile: SwimmerProfile, onSuccess: () -> Unit = {}) {
        viewModelScope.launch {
            try {
                repository.saveProfile(profile)
                refresh()
                _uiState.update { it.copy(message = "Athlete Passport saved.") }
                onSuccess()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(errorMessage = e.message ?: "Could not save profile.")
                }
            }
        }
    }

    fun addRaceLog(log: RaceLog, onSuccess: () -> Unit = {}) {
        viewModelScope.launch {
            try {
                val previousLogs = _uiState.value.raceLogs
                val isPb = SwimAnalytics.isNewPersonalBest(
                    previousLogs = previousLogs,
                    stroke = log.stroke,
                    distance = log.distance,
                    course = log.course,
                    timeSeconds = log.timeSeconds,
                )

                repository.addRaceLog(log)
                refresh()

                if (isPb) {
                    repository.currentUserId?.let { userId ->
                        val title = "New Personal Best!"
                        val body = "${log.distance} ${log.stroke}: ${com.swimiq.app.util.SwimTimeUtils.formatSeconds(log.timeSeconds)}"
                        teamRepository.createNotification(userId, "personal_best", title, body)
                        application?.let {
                            SwimNotificationHelper.showLocalNotification(
                                context = it,
                                notificationId = log.hashCode(),
                                title = title,
                                body = body,
                            )
                        }
                    }
                }

                val message = if (isPb) {
                    "🔥 New Personal Best!"
                } else {
                    "Swim session saved."
                }
                _uiState.update { it.copy(message = message) }
                onSuccess()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(errorMessage = e.message ?: "Could not save session.")
                }
            }
        }
    }

    fun deleteRaceLog(id: String) {
        viewModelScope.launch {
            try {
                repository.deleteRaceLog(id)
                refresh()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(errorMessage = e.message ?: "Could not delete session.")
                }
            }
        }
    }

    fun addGoal(goal: Goal, onSuccess: () -> Unit = {}) {
        viewModelScope.launch {
            try {
                repository.addGoal(goal)
                refresh()
                _uiState.update { it.copy(message = "Goal saved.") }
                onSuccess()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(errorMessage = e.message ?: "Could not save goal.")
                }
            }
        }
    }

    fun deleteGoal(id: String) {
        viewModelScope.launch {
            try {
                repository.deleteGoal(id)
                refresh()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(errorMessage = e.message ?: "Could not delete goal.")
                }
            }
        }
    }

    fun addMeetResult(result: MeetResult, onSuccess: () -> Unit = {}) {
        viewModelScope.launch {
            try {
                repository.addMeetResult(result)
                refresh()
                _uiState.update { it.copy(message = "Meet result saved.") }
                onSuccess()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(errorMessage = e.message ?: "Could not save meet result.")
                }
            }
        }
    }

    fun deleteMeetResult(id: String) {
        viewModelScope.launch {
            try {
                repository.deleteMeetResult(id)
                refresh()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(errorMessage = e.message ?: "Could not delete meet result.")
                }
            }
        }
    }

    fun selectPlannedMeet(meetId: String?) {
        viewModelScope.launch {
            _uiState.update { it.copy(selectedPlannedMeetId = meetId) }
            if (meetId != null) {
                try {
                    val notes = meetPlannerRepository.getHeatNotes(meetId)
                    _uiState.update { it.copy(heatNotes = notes) }
                } catch (e: Exception) {
                    _uiState.update { it.copy(errorMessage = e.message) }
                }
            } else {
                _uiState.update { it.copy(heatNotes = emptyList()) }
            }
        }
    }

    fun addPlannedMeet(meet: PlannedMeet) {
        viewModelScope.launch {
            try {
                meetPlannerRepository.addPlannedMeet(meet)
                refresh()
                _uiState.update { it.copy(message = "Meet added to calendar.") }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun deletePlannedMeet(id: String) {
        viewModelScope.launch {
            try {
                meetPlannerRepository.deletePlannedMeet(id)
                refresh()
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun addHeatNote(note: MeetHeatNote) {
        viewModelScope.launch {
            try {
                meetPlannerRepository.addHeatNote(note)
                selectPlannedMeet(note.plannedMeetId)
                _uiState.update { it.copy(message = "Heat note saved.") }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun deleteHeatNote(id: String) {
        viewModelScope.launch {
            try {
                meetPlannerRepository.deleteHeatNote(id)
                selectPlannedMeet(_uiState.value.selectedPlannedMeetId)
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

    fun signOut(onComplete: () -> Unit) {
        viewModelScope.launch {
            repository.currentUserId?.let { cache?.clear(it) }
            repository.signOut()
            _uiState.value = SwimUiState(isLoading = false)
            onComplete()
        }
    }
}

class AuthViewModelFactory : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(AuthViewModel::class.java)) {
            return AuthViewModel() as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}

class SwimViewModelFactory(
    private val application: Application,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(SwimViewModel::class.java)) {
            return SwimViewModel(
                cache = SwimCache(application),
                application = application,
            ) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
