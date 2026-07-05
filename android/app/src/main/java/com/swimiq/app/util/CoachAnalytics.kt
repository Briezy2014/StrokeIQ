package com.swimiq.app.util

import com.swimiq.app.data.model.Goal
import com.swimiq.app.data.model.RaceLog
import com.swimiq.app.data.model.SwimmerTeamStats
import java.time.LocalDate
import java.time.format.DateTimeParseException
import java.time.temporal.ChronoUnit

object CoachAnalytics {
    fun sessionsInLastDays(logs: List<RaceLog>, days: Long): Int {
        val cutoff = LocalDate.now().minusDays(days)
        return logs.count { log ->
            parseDate(log.date)?.let { !it.isBefore(cutoff) } ?: false
        }
    }

    fun teamAverageScore(stats: List<SwimmerTeamStats>): Double {
        if (stats.isEmpty()) return 0.0
        return stats.map { it.swimIQScore }.average()
    }

    fun teamTotalSessions(stats: List<SwimmerTeamStats>): Int {
        return stats.sumOf { it.sessionCount }
    }

    fun teamAttendanceRate(stats: List<SwimmerTeamStats>, days: Long = 7): Double {
        if (stats.isEmpty()) return 0.0
        val active = stats.count { sessionsInLastDays(it.raceLogs, days) > 0 }
        return (active.toDouble() / stats.size) * 100.0
    }

    fun topPerformers(stats: List<SwimmerTeamStats>, limit: Int = 3): List<SwimmerTeamStats> {
        return stats
            .filter { it.sessionCount > 0 }
            .sortedByDescending { it.swimIQScore }
            .take(limit)
    }

    fun upcomingGoalDeadlines(goals: List<Goal>, withinDays: Long = 14): List<Goal> {
        val today = LocalDate.now()
        val horizon = today.plusDays(withinDays)
        return goals.filter { goal ->
            val target = goal.targetDate?.let { parseDate(it) } ?: return@filter false
            !target.isBefore(today) && !target.isAfter(horizon)
        }.sortedBy { it.targetDate }
    }

    private fun parseDate(value: String): LocalDate? {
        return try {
            LocalDate.parse(value)
        } catch (_: DateTimeParseException) {
            null
        }
    }
}
