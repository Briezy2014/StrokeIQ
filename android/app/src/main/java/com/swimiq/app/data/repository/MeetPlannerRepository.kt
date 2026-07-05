package com.swimiq.app.data.repository

import com.swimiq.app.data.SupabaseProvider
import com.swimiq.app.data.model.MeetHeatNote
import com.swimiq.app.data.model.PlannedMeet
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order

class MeetPlannerRepository {
    private val client get() = SupabaseProvider.client
    private val db get() = client.postgrest
    private val swimRepo get() = SwimRepository()

    suspend fun getPlannedMeets(): List<PlannedMeet> {
        val userId = swimRepo.requireUserIdPublic()
        return db.from("planned_meets")
            .select {
                filter { eq("user_id", userId) }
                order("meet_date", Order.ASCENDING)
            }
            .decodeList<PlannedMeet>()
    }

    suspend fun getUpcomingMeets(): List<PlannedMeet> {
        return getPlannedMeets().filter { it.meetDate >= java.time.LocalDate.now().toString() }
    }

    suspend fun addPlannedMeet(meet: PlannedMeet): PlannedMeet {
        val userId = swimRepo.requireUserIdPublic()
        db.from("planned_meets").insert(meet.copy(userId = userId))
        return getPlannedMeets().last { it.meetName == meet.meetName && it.meetDate == meet.meetDate }
    }

    suspend fun deletePlannedMeet(id: String) {
        db.from("planned_meets").delete { filter { eq("id", id) } }
    }

    suspend fun getHeatNotes(plannedMeetId: String): List<MeetHeatNote> {
        val userId = swimRepo.requireUserIdPublic()
        return db.from("meet_heat_notes")
            .select {
                filter {
                    eq("user_id", userId)
                    eq("planned_meet_id", plannedMeetId)
                }
                order("event", Order.ASCENDING)
            }
            .decodeList<MeetHeatNote>()
    }

    suspend fun addHeatNote(note: MeetHeatNote): MeetHeatNote {
        val userId = swimRepo.requireUserIdPublic()
        db.from("meet_heat_notes").insert(note.copy(userId = userId))
        return getHeatNotes(note.plannedMeetId).last {
            it.event == note.event && it.heatNumber == note.heatNumber
        }
    }

    suspend fun deleteHeatNote(id: String) {
        db.from("meet_heat_notes").delete { filter { eq("id", id) } }
    }
}
