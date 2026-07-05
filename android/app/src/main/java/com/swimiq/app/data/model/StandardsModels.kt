package com.swimiq.app.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class TimeStandard(
    @SerialName("age_group") val ageGroup: String,
    val gender: String,
    val stroke: String,
    val distance: Int,
    val course: String,
    @SerialName("standard_level") val standardLevel: String,
    @SerialName("time_seconds") val timeSeconds: Double,
    val season: String = "2024-2028",
)

@Serializable
data class PlannedMeet(
    val id: String? = null,
    @SerialName("user_id") val userId: String? = null,
    @SerialName("meet_name") val meetName: String = "",
    @SerialName("meet_date") val meetDate: String = "",
    val location: String? = null,
    val notes: String? = null,
)

@Serializable
data class MeetHeatNote(
    val id: String? = null,
    @SerialName("user_id") val userId: String? = null,
    @SerialName("planned_meet_id") val plannedMeetId: String = "",
    val event: String = "",
    @SerialName("heat_number") val heatNumber: Int? = null,
    @SerialName("lane_number") val laneNumber: Int? = null,
    val notes: String? = null,
)

data class CutResult(
    val level: String,
    val timeSeconds: Double,
)

data class CutGapAnalysis(
    val currentLevel: String?,
    val nextLevel: String?,
    val swimmerTime: Double,
    val nextCutTime: Double?,
    val gapSeconds: Double?,
) {
    val gapLabel: String
        get() = when {
            currentLevel == "AAAA" -> "Highest cut achieved!"
            gapSeconds == null || nextLevel == null -> "No cut yet — keep training"
            else -> String.format("%.2fs from %s", gapSeconds, nextLevel)
        }
}

data class PersonalBestCut(
    val stroke: String,
    val distance: Int,
    val course: String,
    val swimmerTime: Double,
    val highestCut: String?,
    val gap: CutGapAnalysis,
)
