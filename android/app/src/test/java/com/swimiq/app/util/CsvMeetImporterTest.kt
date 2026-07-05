package com.swimiq.app.util

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CsvMeetImporterTest {
    @Test
    fun parse_validRow() {
        val csv = """
            swimmer_name,meet_name,meet_date,event,swim_time,course
            Aspyn,State Meet,2026-03-01,100 Fly,62.45,SCY
        """.trimIndent()

        val result = CsvMeetImporter.parse(csv)
        assertEquals(1, result.imported.size)
        assertEquals("Aspyn", result.imported.first().swimmerName)
        assertEquals(62.45, result.imported.first().swimTime, 0.01)
        assertTrue(result.errors.isEmpty())
    }

    @Test
    fun parse_reportsInvalidLine() {
        val result = CsvMeetImporter.parse("bad,line")
        assertTrue(result.imported.isEmpty())
        assertTrue(result.errors.isNotEmpty())
    }
}
