package com.swimiq.app.data.repository

import com.swimiq.app.data.SupabaseProvider
import com.swimiq.app.data.model.AppNotification
import com.swimiq.app.data.model.Goal
import com.swimiq.app.data.model.MeetResult
import com.swimiq.app.data.model.RaceLog
import com.swimiq.app.data.model.SwimmerProfile
import com.swimiq.app.data.model.SwimmerTeamStats
import com.swimiq.app.data.model.Team
import com.swimiq.app.data.model.TeamMember
import com.swimiq.app.data.model.UserProfile
import com.swimiq.app.data.model.UserRole
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import java.time.Instant

class TeamRepository {
    private val client get() = SupabaseProvider.client
    private val db get() = client.postgrest
    private val swimRepo get() = SwimRepository()

    suspend fun getUserProfile(): UserProfile? {
        val userId = swimRepo.currentUserId ?: return null
        return db.from("user_profiles")
            .select { filter { eq("user_id", userId) } }
            .decodeList<UserProfile>()
            .firstOrNull()
    }

    suspend fun saveUserProfile(role: String, displayName: String? = null): UserProfile {
        val userId = swimRepo.requireUserIdPublic()
        val existing = getUserProfile()
        val row = UserProfile(
            id = existing?.id,
            userId = userId,
            role = role,
            displayName = displayName ?: existing?.displayName,
        )

        if (existing?.id != null) {
            db.from("user_profiles").update(row) {
                filter { eq("id", existing.id!!) }
            }
        } else {
            db.from("user_profiles").insert(row)
        }
        return row
    }

    suspend fun acceptPendingInvites() {
        val userId = swimRepo.currentUserId ?: return
        val email = swimRepo.currentUserEmail?.lowercase() ?: return

        val pending = db.from("team_members")
            .select {
                filter {
                    eq("invite_email", email)
                    eq("status", "pending")
                }
            }
            .decodeList<TeamMember>()

        for (member in pending) {
            db.from("team_members").update(
                member.copy(
                    swimmerUserId = userId,
                    status = "active",
                    joinedAt = Instant.now().toString(),
                ),
            ) {
                filter { eq("id", member.id!!) }
            }

            createNotification(
                userId = userId,
                type = "team_invite",
                title = "Welcome to the team!",
                body = "You've been added to your coach's SwimIQ roster.",
            )
        }
    }

    suspend fun getTeams(): List<Team> {
        val userId = swimRepo.requireUserIdPublic()
        return db.from("teams")
            .select {
                filter { eq("coach_user_id", userId) }
                order("created_at", Order.DESCENDING)
            }
            .decodeList<Team>()
    }

    suspend fun createTeam(name: String, clubName: String?): Team {
        val userId = swimRepo.requireUserIdPublic()
        val team = Team(
            coachUserId = userId,
            name = name.trim(),
            clubName = clubName?.trim()?.ifBlank { null },
        )
        db.from("teams").insert(team)
        return getTeams().first { it.name == team.name }
    }

    suspend fun getTeamMembers(teamId: String): List<TeamMember> {
        return db.from("team_members")
            .select {
                filter { eq("team_id", teamId) }
                order("created_at", Order.ASCENDING)
            }
            .decodeList<TeamMember>()
    }

    suspend fun inviteSwimmer(
        teamId: String,
        email: String,
        displayName: String?,
    ): TeamMember {
        val member = TeamMember(
            teamId = teamId,
            inviteEmail = email.trim().lowercase(),
            displayName = displayName?.trim()?.ifBlank { null },
            status = "pending",
        )
        db.from("team_members").insert(member)
        return getTeamMembers(teamId).last { it.inviteEmail == member.inviteEmail }
    }

    suspend fun removeMember(memberId: String) {
        db.from("team_members").delete {
            filter { eq("id", memberId) }
        }
    }

    suspend fun loadTeamStats(teamId: String): List<SwimmerTeamStats> {
        val members = getTeamMembers(teamId).filter { it.status == "active" && it.swimmerUserId != null }
        return members.map { member ->
            val userId = member.swimmerUserId!!
            SwimmerTeamStats(
                member = member,
                profile = fetchSwimmerProfile(userId),
                raceLogs = fetchRaceLogsForUser(userId),
                goals = fetchGoalsForUser(userId),
                meetResults = fetchMeetResultsForUser(userId),
            )
        }
    }

    suspend fun bulkImportMeetResults(
        teamId: String,
        results: List<MeetResult>,
    ): Pair<Int, List<String>> {
        val members = getTeamMembers(teamId)
        val emailToUserId = members
            .filter { it.swimmerUserId != null }
            .associate { it.inviteEmail.lowercase() to it.swimmerUserId!! }

        val nameToUserId = members
            .filter { it.swimmerUserId != null }
            .associate { (it.displayName ?: it.inviteEmail).lowercase() to it.swimmerUserId!! }

        var imported = 0
        val errors = mutableListOf<String>()

        for (result in results) {
            val key = result.swimmerName.trim().lowercase()
            val userId = nameToUserId[key] ?: emailToUserId[key]
            if (userId == null) {
                errors.add("No roster match for swimmer: ${result.swimmerName}")
                continue
            }

            try {
                db.from("meet_results").insert(
                    result.copy(userId = userId),
                )
                imported++
            } catch (e: Exception) {
                errors.add("${result.swimmerName}: ${e.message}")
            }
        }

        return imported to errors
    }

    suspend fun getNotifications(): List<AppNotification> {
        val userId = swimRepo.requireUserIdPublic()
        return db.from("notifications")
            .select {
                filter { eq("user_id", userId) }
                order("created_at", Order.DESCENDING)
            }
            .decodeList<AppNotification>()
    }

    suspend fun createNotification(
        userId: String,
        type: String,
        title: String,
        body: String,
    ) {
        db.from("notifications").insert(
            AppNotification(
                userId = userId,
                type = type,
                title = title,
                body = body,
            ),
        )
    }

    suspend fun markNotificationRead(id: String) {
        db.from("notifications").update(mapOf("read" to true)) {
            filter { eq("id", id) }
        }
    }

    suspend fun markAllNotificationsRead() {
        val userId = swimRepo.requireUserIdPublic()
        db.from("notifications").update(mapOf("read" to true)) {
            filter { eq("user_id", userId) }
        }
    }

    private suspend fun fetchSwimmerProfile(userId: String): SwimmerProfile? {
        return db.from("swimmers")
            .select { filter { eq("user_id", userId) } }
            .decodeList<SwimmerProfile>()
            .firstOrNull()
    }

    private suspend fun fetchRaceLogsForUser(userId: String): List<RaceLog> {
        return db.from("race_logs")
            .select {
                filter { eq("user_id", userId) }
                order("date", Order.DESCENDING)
            }
            .decodeList<RaceLog>()
    }

    private suspend fun fetchGoalsForUser(userId: String): List<Goal> {
        return db.from("goals")
            .select {
                filter { eq("user_id", userId) }
                order("target_date", Order.ASCENDING)
            }
            .decodeList<Goal>()
    }

    private suspend fun fetchMeetResultsForUser(userId: String): List<MeetResult> {
        return db.from("meet_results")
            .select {
                filter { eq("user_id", userId) }
                order("meet_date", Order.DESCENDING)
            }
            .decodeList<MeetResult>()
    }
}
