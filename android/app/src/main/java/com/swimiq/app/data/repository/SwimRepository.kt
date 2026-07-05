package com.swimiq.app.data.repository

import com.swimiq.app.data.SupabaseProvider
import com.swimiq.app.data.model.Goal
import com.swimiq.app.data.model.MeetResult
import com.swimiq.app.data.model.RaceLog
import com.swimiq.app.data.model.SwimmerProfile
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order

class SwimRepository {
    private val client get() = SupabaseProvider.client
    private val auth get() = client.auth
    private val db get() = client.postgrest

    val currentUserId: String?
        get() = auth.currentUserOrNull()?.id

    val currentUserEmail: String?
        get() = auth.currentUserOrNull()?.email

    suspend fun isLoggedIn(): Boolean = auth.currentUserOrNull() != null

    suspend fun signIn(email: String, password: String) {
        auth.signInWith(Email) {
            this.email = email.trim()
            this.password = password
        }
    }

    suspend fun signUp(email: String, password: String) {
        auth.signUpWith(Email) {
            this.email = email.trim()
            this.password = password
        }
    }

    suspend fun signOut() {
        auth.signOut()
    }

    private fun requireUserId(): String =
        currentUserId ?: throw IllegalStateException("Not authenticated")

    suspend fun getProfile(): SwimmerProfile? {
        val userId = requireUserId()
        return db.from("swimmers")
            .select {
                filter { eq("user_id", userId) }
            }
            .decodeList<SwimmerProfile>()
            .firstOrNull()
    }

    suspend fun saveProfile(profile: SwimmerProfile) {
        val userId = requireUserId()
        val existing = getProfile()
        val row = profile.copy(
            userId = userId,
            swimmerName = profile.swimmerName.ifBlank {
                profile.preferredName
                    ?: listOfNotNull(profile.firstName, profile.lastName)
                        .joinToString(" ")
                        .ifBlank { currentUserEmail.orEmpty() }
            },
        )

        if (existing?.id != null) {
            db.from("swimmers").update(row) {
                filter { eq("id", existing.id!!) }
            }
        } else {
            db.from("swimmers").insert(row)
        }
    }

    suspend fun getRaceLogs(): List<RaceLog> {
        val userId = requireUserId()
        return db.from("race_logs")
            .select {
                filter { eq("user_id", userId) }
                order("date", Order.DESCENDING)
            }
            .decodeList<RaceLog>()
    }

    suspend fun addRaceLog(log: RaceLog) {
        val userId = requireUserId()
        val profile = getProfile()
        val swimmerName = profile?.swimmerName?.ifBlank {
            profile.preferredName ?: currentUserEmail.orEmpty()
        } ?: currentUserEmail.orEmpty()

        db.from("race_logs").insert(
            log.copy(
                userId = userId,
                swimmer = swimmerName,
                event = log.event ?: "${log.distance} ${log.stroke}",
            ),
        )
    }

    suspend fun deleteRaceLog(id: String) {
        db.from("race_logs").delete {
            filter { eq("id", id) }
        }
    }

    suspend fun getGoals(): List<Goal> {
        val userId = requireUserId()
        return db.from("goals")
            .select {
                filter { eq("user_id", userId) }
                order("target_date", Order.DESCENDING)
            }
            .decodeList<Goal>()
    }

    suspend fun addGoal(goal: Goal) {
        val userId = requireUserId()
        val profile = getProfile()
        val swimmerName = profile?.swimmerName?.ifBlank {
            profile.preferredName ?: currentUserEmail.orEmpty()
        } ?: currentUserEmail.orEmpty()

        db.from("goals").insert(
            goal.copy(
                userId = userId,
                swimmerName = swimmerName,
            ),
        )
    }

    suspend fun deleteGoal(id: String) {
        db.from("goals").delete {
            filter { eq("id", id) }
        }
    }

    suspend fun getMeetResults(): List<MeetResult> {
        val userId = requireUserId()
        return db.from("meet_results")
            .select {
                filter { eq("user_id", userId) }
                order("meet_date", Order.DESCENDING)
            }
            .decodeList<MeetResult>()
    }

    suspend fun addMeetResult(result: MeetResult) {
        val userId = requireUserId()
        val profile = getProfile()
        val swimmerName = profile?.swimmerName?.ifBlank {
            profile.preferredName ?: currentUserEmail.orEmpty()
        } ?: currentUserEmail.orEmpty()

        db.from("meet_results").insert(
            result.copy(
                userId = userId,
                swimmerName = swimmerName,
            ),
        )
    }

    suspend fun deleteMeetResult(id: String) {
        db.from("meet_results").delete {
            filter { eq("id", id) }
        }
    }
}
