package com.swimiq.app.util

import android.content.Context
import com.swimiq.app.data.model.CutGapAnalysis
import com.swimiq.app.data.model.CutResult
import com.swimiq.app.data.model.PersonalBestCut
import com.swimiq.app.data.model.RaceLog
import com.swimiq.app.data.model.SwimmerProfile
import com.swimiq.app.data.model.TimeStandard
import kotlinx.serialization.json.Json
import java.time.LocalDate
import java.time.Period
import java.time.format.DateTimeParseException

object StandardsService {
    private val json = Json { ignoreUnknownKeys = true }
    private val levelOrder = listOf("B", "BB", "A", "AA", "AAA", "AAAA")

    fun loadFromAssets(context: Context): List<TimeStandard> {
        val raw = context.assets.open("usa_2028_motivational_standards.json")
            .bufferedReader()
            .use { it.readText() }
        return json.decodeFromString(raw)
    }

    fun ageGroupFromProfile(profile: SwimmerProfile?): String {
        val birthday = profile?.birthday?.let { parseDate(it) } ?: return "11-12"
        val age = Period.between(birthday, LocalDate.now()).years
        return when {
            age <= 10 -> "10 & under"
            age <= 12 -> "11-12"
            age <= 14 -> "13-14"
            age <= 16 -> "15-16"
            else -> "17-18"
        }
    }

    fun genderFromProfile(profile: SwimmerProfile?): String {
        // Default; future: explicit gender field on profile
        return "Girls"
    }

    fun normalizeStroke(stroke: String): String {
        return when (stroke.lowercase()) {
            "free", "freestyle" -> "Freestyle"
            "back", "backstroke" -> "Backstroke"
            "breast", "breaststroke" -> "Breaststroke"
            "fly", "butterfly" -> "Butterfly"
            "im" -> "Individual Medley"
            else -> stroke
        }
    }

    fun highestCut(
        standards: List<TimeStandard>,
        stroke: String,
        distance: Int,
        course: String,
        swimmerTime: Double,
        ageGroup: String,
        gender: String,
    ): String? {
        val strokeNorm = normalizeStroke(stroke)
        val matching = standards.filter {
            it.stroke == strokeNorm &&
                it.distance == distance &&
                it.course == course &&
                it.ageGroup == ageGroup &&
                it.gender == gender &&
                swimmerTime <= it.timeSeconds
        }
        if (matching.isEmpty()) return null
        return matching.maxByOrNull { levelOrder.indexOf(it.standardLevel) }?.standardLevel
    }

    fun nextCutGap(
        standards: List<TimeStandard>,
        stroke: String,
        distance: Int,
        course: String,
        swimmerTime: Double,
        ageGroup: String,
        gender: String,
    ): CutGapAnalysis {
        val strokeNorm = normalizeStroke(stroke)
        val eventStandards = standards.filter {
            it.stroke == strokeNorm &&
                it.distance == distance &&
                it.course == course &&
                it.ageGroup == ageGroup &&
                it.gender == gender
        }.sortedBy { levelOrder.indexOf(it.standardLevel) }

        val current = highestCut(standards, stroke, distance, course, swimmerTime, ageGroup, gender)
        val currentIndex = current?.let { levelOrder.indexOf(it) } ?: -1
        val nextLevel = levelOrder.getOrNull(currentIndex + 1)
        val nextStandard = eventStandards.firstOrNull { it.standardLevel == nextLevel }
        val gap = nextStandard?.let { (swimmerTime - it.timeSeconds).coerceAtLeast(0.0) }

        return CutGapAnalysis(
            currentLevel = current,
            nextLevel = nextLevel,
            swimmerTime = swimmerTime,
            nextCutTime = nextStandard?.timeSeconds,
            gapSeconds = gap,
        )
    }

    fun personalBestCuts(
        standards: List<TimeStandard>,
        logs: List<RaceLog>,
        profile: SwimmerProfile?,
    ): List<PersonalBestCut> {
        val ageGroup = ageGroupFromProfile(profile)
        val gender = genderFromProfile(profile)
        val pbs = SwimAnalytics.personalBests(logs)

        return pbs.map { pb ->
            val gap = nextCutGap(
                standards = standards,
                stroke = pb.stroke,
                distance = pb.distance,
                course = pb.course,
                swimmerTime = pb.timeSeconds,
                ageGroup = ageGroup,
                gender = gender,
            )
            PersonalBestCut(
                stroke = pb.stroke,
                distance = pb.distance,
                course = pb.course,
                swimmerTime = pb.timeSeconds,
                highestCut = gap.currentLevel,
                gap = gap,
            )
        }
    }

    fun overallHighestCut(cuts: List<PersonalBestCut>): String {
        if (cuts.isEmpty()) return "No cut yet"
        val achieved = cuts.mapNotNull { it.highestCut }
        if (achieved.isEmpty()) return "No cut yet"
        return achieved.minByOrNull { levelOrder.indexOf(it) } ?: "No cut yet"
    }

    private fun parseDate(value: String): LocalDate? {
        return try {
            LocalDate.parse(value)
        } catch (_: DateTimeParseException) {
            null
        }
    }
}
