package com.swimiq.app.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.swimiq.app.data.model.Goal
import com.swimiq.app.data.model.MeetResult
import com.swimiq.app.data.model.RaceLog
import com.swimiq.app.data.model.SwimmerProfile
import com.swimiq.app.data.repository.SwimRepository
import com.swimiq.app.util.SwimTimeUtils
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
    val profile: SwimmerProfile? = null,
    val raceLogs: List<RaceLog> = emptyList(),
    val goals: List<Goal> = emptyList(),
    val meetResults: List<MeetResult> = emptyList(),
    val userEmail: String? = null,
    val message: String? = null,
    val errorMessage: String? = null,
) {
    val swimIQScore: Int
        get() = SwimTimeUtils.calculateSwimIQScore(
            sessionCount = raceLogs.size,
            goalCount = goals.size,
            personalBestCount = SwimTimeUtils.personalBestCount(raceLogs),
        )

    val personalBestCount: Int
        get() = SwimTimeUtils.personalBestCount(raceLogs)

    val displayName: String
        get() = profile?.preferredName
            ?: listOfNotNull(profile?.firstName, profile?.lastName)
                .joinToString(" ")
                .ifBlank { profile?.swimmerName.orEmpty() }
                .ifBlank { userEmail.orEmpty() }
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
) : ViewModel() {
    private val _uiState = MutableStateFlow(SwimUiState())
    val uiState: StateFlow<SwimUiState> = _uiState.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _uiState.update {
                it.copy(
                    isLoading = it.raceLogs.isEmpty(),
                    isRefreshing = it.raceLogs.isNotEmpty(),
                    errorMessage = null,
                )
            }
            try {
                val profile = repository.getProfile()
                val logs = repository.getRaceLogs()
                val goals = repository.getGoals()
                val meets = repository.getMeetResults()
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        isRefreshing = false,
                        profile = profile,
                        raceLogs = logs,
                        goals = goals,
                        meetResults = meets,
                        userEmail = repository.currentUserEmail,
                    )
                }
            } catch (e: Exception) {
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

    fun clearMessage() {
        _uiState.update { it.copy(message = null, errorMessage = null) }
    }

    fun saveProfile(profile: SwimmerProfile, onSuccess: () -> Unit = {}) {
        viewModelScope.launch {
            try {
                repository.saveProfile(profile)
                refresh()
                _uiState.update { it.copy(message = "Profile saved.") }
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
                repository.addRaceLog(log)
                refresh()
                _uiState.update { it.copy(message = "Training session saved.") }
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

    fun signOut(onComplete: () -> Unit) {
        viewModelScope.launch {
            repository.signOut()
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

class SwimViewModelFactory : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(SwimViewModel::class.java)) {
            return SwimViewModel() as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
