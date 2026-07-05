package com.swimiq.app.util

import com.swimiq.app.data.model.TimeStandard
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class StandardsServiceTest {
    private val standards = listOf(
        TimeStandard(
            ageGroup = "11-12",
            gender = "Girls",
            stroke = "Freestyle",
            distance = 50,
            course = "SCY",
            standardLevel = "B",
            timeSeconds = 33.99,
        ),
        TimeStandard(
            ageGroup = "11-12",
            gender = "Girls",
            stroke = "Freestyle",
            distance = 50,
            course = "SCY",
            standardLevel = "BB",
            timeSeconds = 31.69,
        ),
        TimeStandard(
            ageGroup = "11-12",
            gender = "Girls",
            stroke = "Freestyle",
            distance = 50,
            course = "SCY",
            standardLevel = "A",
            timeSeconds = 29.29,
        ),
        TimeStandard(
            ageGroup = "11-12",
            gender = "Girls",
            stroke = "Freestyle",
            distance = 50,
            course = "SCY",
            standardLevel = "AA",
            timeSeconds = 28.09,
        ),
        TimeStandard(
            ageGroup = "11-12",
            gender = "Girls",
            stroke = "Freestyle",
            distance = 50,
            course = "SCY",
            standardLevel = "AAA",
            timeSeconds = 26.99,
        ),
        TimeStandard(
            ageGroup = "11-12",
            gender = "Girls",
            stroke = "Freestyle",
            distance = 50,
            course = "SCY",
            standardLevel = "AAAA",
            timeSeconds = 25.79,
        ),
    )

    @Test
    fun highestCut_returnsBestAchievedLevel() {
        val cut = StandardsService.highestCut(
            standards = standards,
            stroke = "Freestyle",
            distance = 50,
            course = "SCY",
            swimmerTime = 28.50,
            ageGroup = "11-12",
            gender = "Girls",
        )
        assertEquals("A", cut)
    }

    @Test
    fun nextCutGap_calculatesGapToNextLevel() {
        val gap = StandardsService.nextCutGap(
            standards = standards,
            stroke = "Freestyle",
            distance = 50,
            course = "SCY",
            swimmerTime = 28.50,
            ageGroup = "11-12",
            gender = "Girls",
        )
        assertEquals("A", gap.currentLevel)
        assertEquals("AA", gap.nextLevel)
        assertNotNull(gap.gapSeconds)
        assertEquals(0.41, gap.gapSeconds!!, 0.01)
    }
}
