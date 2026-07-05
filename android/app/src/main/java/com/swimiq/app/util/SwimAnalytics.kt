package com.swimiq.app.util

import com.swimiq.app.data.model.Goal
import com.swimiq.app.data.model.RaceLog

data class SwimIQScoreBreakdown(
    val totalScore: Int,
    val baseScore: Int = 500,
    val sessionPoints: Int,
    val goalPoints: Int,
    val personalBestPoints: Int,
    val sessionCount: Int,
    val goalCount: Int,
    val personalBestCount: Int,
) {
    val explanation: List<String>
        get() = buildList {
            if (sessionCount == 0) {
                add("Add swim sessions to start your SwimIQ Score.")
                return@buildList
            }
            add("Base score: $baseScore")
            if (sessionCount > 0) {
                add("Sessions: $sessionCount × 5 = +$sessionPoints")
            }
            if (goalCount > 0) {
                add("Goals: $goalCount × 20 = +$goalPoints")
            }
            if (personalBestCount > 0) {
                add("Personal bests: $personalBestCount × 25 = +$personalBestPoints")
            }
            add("Total: $totalScore / 1000")
        }
}

object SwimAnalytics {
    fun personalBests(logs: List<RaceLog>): List<RaceLog> {
        val valid = logs.filter { it.timeSeconds > 0 }
        if (valid.isEmpty()) return emptyList()

        val bestByEvent = mutableMapOf<Triple<String, Int, String>, RaceLog>()
        for (log in valid) {
            val key = Triple(log.stroke, log.distance, log.course)
            val existing = bestByEvent[key]
            if (existing == null || log.timeSeconds < existing.timeSeconds) {
                bestByEvent[key] = log
            }
        }

        return bestByEvent.values.sortedWith(
            compareBy<RaceLog> { it.stroke }.thenBy { it.distance },
        )
    }

    fun isNewPersonalBest(
        previousLogs: List<RaceLog>,
        stroke: String,
        distance: Int,
        course: String,
        timeSeconds: Double,
    ): Boolean {
        val matching = previousLogs.filter {
            it.stroke == stroke &&
                it.distance == distance &&
                it.course == course &&
                it.timeSeconds > 0
        }
        if (matching.isEmpty()) return true
        return timeSeconds < matching.minOf { it.timeSeconds }
    }

    fun calculateSwimIQScore(
        raceLogs: List<RaceLog>,
        goals: List<Goal>,
    ): SwimIQScoreBreakdown {
        if (raceLogs.isEmpty()) {
            return SwimIQScoreBreakdown(
                totalScore = 0,
                sessionPoints = 0,
                goalPoints = 0,
                personalBestPoints = 0,
                sessionCount = 0,
                goalCount = goals.size,
                personalBestCount = 0,
            )
        }

        val sessionCount = raceLogs.size
        val goalCount = goals.size
        val pbCount = personalBests(raceLogs).size
        val sessionPoints = sessionCount * 5
        val goalPoints = goalCount * 20
        val personalBestPoints = pbCount * 25
        val total = (500 + sessionPoints + goalPoints + personalBestPoints).coerceAtMost(1000)

        return SwimIQScoreBreakdown(
            totalScore = total,
            sessionPoints = sessionPoints,
            goalPoints = goalPoints,
            personalBestPoints = personalBestPoints,
            sessionCount = sessionCount,
            goalCount = goalCount,
            personalBestCount = pbCount,
        )
    }

    fun bestTime(logs: List<RaceLog>): String {
        val times = logs.map { it.timeSeconds }.filter { it > 0 }
        if (times.isEmpty()) return "—"
        return SwimTimeUtils.formatSeconds(times.min())
    }

    fun averageTime(logs: List<RaceLog>): String {
        val times = logs.map { it.timeSeconds }.filter { it > 0 }
        if (times.isEmpty()) return "—"
        return SwimTimeUtils.formatSeconds(times.average())
    }

    fun readiness(
        raceLogs: List<RaceLog>,
        goals: List<Goal>,
    ): String {
        val breakdown = calculateSwimIQScore(raceLogs, goals)
        return when {
            breakdown.totalScore >= 800 && raceLogs.isNotEmpty() && goals.isNotEmpty() -> "Race Ready"
            breakdown.totalScore >= 600 -> "Building"
            raceLogs.isNotEmpty() -> "Developing"
            else -> "Getting Started"
        }
    }

    fun currentFocus(profile: com.swimiq.app.data.model.SwimmerProfile?): String {
        val favorite = profile?.favoriteEvent?.trim().orEmpty()
        if (favorite.isNotEmpty()) return favorite
        val primary = profile?.primaryStroke?.trim().orEmpty()
        if (primary.isNotEmpty()) return primary
        return "Add focus event"
    }

    fun nextMeet(meetResults: List<com.swimiq.app.data.model.MeetResult>): String {
        if (meetResults.isEmpty()) return "Add meet results"
        return meetResults.maxByOrNull { it.meetDate }?.meetName ?: "Add meet results"
    }
}
