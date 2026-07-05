package com.swimiq.app.util

import com.swimiq.app.data.model.MeetResult

data class CsvImportRow(
    val swimmerName: String,
    val meetName: String,
    val meetDate: String,
    val event: String,
    val swimTime: Double,
    val course: String,
)

data class CsvImportResult(
    val imported: List<MeetResult>,
    val errors: List<String>,
)

object CsvMeetImporter {
    private val header = listOf(
        "swimmer_name",
        "meet_name",
        "meet_date",
        "event",
        "swim_time",
        "course",
    )

    fun parse(text: String): CsvImportResult {
        val lines = text.lines()
            .map { it.trim() }
            .filter { it.isNotEmpty() }

        if (lines.isEmpty()) {
            return CsvImportResult(emptyList(), listOf("CSV is empty."))
        }

        val startIndex = if (lines.first().lowercase().contains("swimmer_name")) 1 else 0
        val imported = mutableListOf<MeetResult>()
        val errors = mutableListOf<String>()

        for (i in startIndex until lines.size) {
            val line = lines[i]
            val parts = line.split(",").map { it.trim() }
            if (parts.size < 5) {
                errors.add("Line ${i + 1}: expected at least 5 columns.")
                continue
            }

            try {
                val row = CsvImportRow(
                    swimmerName = parts[0],
                    meetName = parts[1],
                    meetDate = parts[2],
                    event = parts[3],
                    swimTime = SwimTimeUtils.toSeconds(parts[4]),
                    course = parts.getOrNull(5)?.ifBlank { "SCY" } ?: "SCY",
                )

                if (row.swimmerName.isBlank() || row.meetName.isBlank() || row.event.isBlank()) {
                    errors.add("Line ${i + 1}: swimmer, meet, and event are required.")
                    continue
                }

                imported.add(
                    MeetResult(
                        swimmerName = row.swimmerName,
                        meetName = row.meetName,
                        meetDate = row.meetDate,
                        event = row.event,
                        swimTime = row.swimTime,
                        course = row.course,
                    ),
                )
            } catch (e: Exception) {
                errors.add("Line ${i + 1}: ${e.message}")
            }
        }

        return CsvImportResult(imported, errors)
    }

    fun template(): String {
        return header.joinToString(",") + "\n" +
            "Aspyn Briez,State Champs,2026-03-15,100 Butterfly,62.45,SCY"
    }
}
