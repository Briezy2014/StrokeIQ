package com.swimiq.app.util

import com.swimiq.app.data.model.Goal
import com.swimiq.app.data.model.RaceLog
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SwimAnalyticsTest {
    private val logs = listOf(
        RaceLog(
            swimmer = "Aspyn",
            stroke = "Freestyle",
            distance = 100,
            course = "SCY",
            timeSeconds = 60.0,
            date = "2026-01-01",
        ),
        RaceLog(
            swimmer = "Aspyn",
            stroke = "Freestyle",
            distance = 100,
            course = "SCY",
            timeSeconds = 55.0,
            date = "2026-02-01",
        ),
    )

    @Test
    fun personalBests_returnsFastestPerEvent() {
        val pbs = SwimAnalytics.personalBests(logs)
        assertEquals(1, pbs.size)
        assertEquals(55.0, pbs.first().timeSeconds, 0.01)
    }

    @Test
    fun isNewPersonalBest_detectsImprovement() {
        assertTrue(
            SwimAnalytics.isNewPersonalBest(
                previousLogs = logs,
                stroke = "Freestyle",
                distance = 100,
                course = "SCY",
                timeSeconds = 54.0,
            ),
        )
    }

    @Test
    fun calculateSwimIQScore_matchesFormula() {
        val breakdown = SwimAnalytics.calculateSwimIQScore(
            raceLogs = logs,
            goals = listOf(
                Goal(
                    swimmerName = "Aspyn",
                    event = "200 Butterfly",
                    goalTime = 120.0,
                    course = "LCM",
                    targetDate = "2026-06-01",
                ),
            ),
        )
        assertEquals(555, breakdown.totalScore)
        assertEquals(10, breakdown.sessionPoints)
        assertEquals(20, breakdown.goalPoints)
        assertEquals(25, breakdown.personalBestPoints)
    }
}
