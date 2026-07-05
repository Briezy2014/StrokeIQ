package com.swimiq.app.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

object UserRole {
    const val SWIMMER = "swimmer"
    const val COACH = "coach"
}

@Serializable
data class UserProfile(
    val id: String? = null,
    @SerialName("user_id") val userId: String? = null,
    val role: String = UserRole.SWIMMER,
    @SerialName("display_name") val displayName: String? = null,
)

@Serializable
data class Team(
    val id: String? = null,
    @SerialName("coach_user_id") val coachUserId: String? = null,
    val name: String = "",
    @SerialName("club_name") val clubName: String? = null,
)

@Serializable
data class TeamMember(
    val id: String? = null,
    @SerialName("team_id") val teamId: String = "",
    @SerialName("swimmer_user_id") val swimmerUserId: String? = null,
    @SerialName("invite_email") val inviteEmail: String = "",
    @SerialName("display_name") val displayName: String? = null,
    val status: String = "pending",
    @SerialName("joined_at") val joinedAt: String? = null,
)

@Serializable
data class AppNotification(
    val id: String? = null,
    @SerialName("user_id") val userId: String? = null,
    val type: String = "",
    val title: String = "",
    val body: String = "",
    val read: Boolean = false,
    @SerialName("created_at") val createdAt: String? = null,
)

data class SwimmerTeamStats(
    val member: TeamMember,
    val profile: SwimmerProfile?,
    val raceLogs: List<RaceLog>,
    val goals: List<Goal>,
    val meetResults: List<MeetResult>,
) {
    val displayLabel: String
        get() = member.displayName
            ?: profile?.preferredName
            ?: profile?.swimmerName
            ?: member.inviteEmail

    val swimIQScore: Int
        get() = com.swimiq.app.util.SwimAnalytics
            .calculateSwimIQScore(raceLogs, goals)
            .totalScore

    val sessionCount: Int
        get() = raceLogs.size

    val recentSessionCount: Int
        get() = com.swimiq.app.util.CoachAnalytics.sessionsInLastDays(raceLogs, 7)
}
