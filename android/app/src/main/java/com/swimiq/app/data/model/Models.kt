package com.swimiq.app.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SwimmerProfile(
    val id: String? = null,
    @SerialName("user_id") val userId: String? = null,
    @SerialName("swimmer_name") val swimmerName: String = "",
    @SerialName("first_name") val firstName: String? = null,
    @SerialName("last_name") val lastName: String? = null,
    @SerialName("preferred_name") val preferredName: String? = null,
    val birthday: String? = null,
    val gender: String? = null,
    @SerialName("graduation_year") val graduationYear: Int? = null,
    val team: String? = null,
    @SerialName("coach_name") val coachName: String? = null,
    @SerialName("primary_stroke") val primaryStroke: String? = null,
    @SerialName("secondary_stroke") val secondaryStroke: String? = null,
    @SerialName("favorite_event") val favoriteEvent: String? = null,
    @SerialName("usa_swimming_id") val usaSwimmingId: String? = null,
    val school: String? = null,
    @SerialName("athlete_notes") val athleteNotes: String? = null,
)

@Serializable
data class RaceLog(
    val id: String? = null,
    @SerialName("user_id") val userId: String? = null,
    val swimmer: String = "",
    val event: String? = null,
    val stroke: String = "",
    val distance: Int = 0,
    val course: String = "SCY",
    @SerialName("time_seconds") val timeSeconds: Double = 0.0,
    val notes: String? = null,
    val date: String = "",
)

@Serializable
data class Goal(
    val id: String? = null,
    @SerialName("user_id") val userId: String? = null,
    @SerialName("swimmer_name") val swimmerName: String = "",
    val event: String = "",
    @SerialName("current_time") val currentTime: Double? = null,
    @SerialName("goal_time") val goalTime: Double = 0.0,
    val course: String = "SCY",
    @SerialName("target_date") val targetDate: String? = null,
)

@Serializable
data class MeetResult(
    val id: String? = null,
    @SerialName("user_id") val userId: String? = null,
    @SerialName("swimmer_name") val swimmerName: String = "",
    @SerialName("meet_name") val meetName: String = "",
    @SerialName("meet_date") val meetDate: String = "",
    val event: String = "",
    @SerialName("swim_time") val swimTime: Double = 0.0,
    val course: String = "SCY",
)
