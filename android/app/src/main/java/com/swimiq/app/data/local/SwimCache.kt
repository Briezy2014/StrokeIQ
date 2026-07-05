package com.swimiq.app.data.local

import android.content.Context
import com.swimiq.app.data.model.Goal
import com.swimiq.app.data.model.MeetResult
import com.swimiq.app.data.model.RaceLog
import com.swimiq.app.data.model.SwimmerProfile
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@Serializable
data class CachedSwimData(
    val profile: SwimmerProfile? = null,
    val raceLogs: List<RaceLog> = emptyList(),
    val goals: List<Goal> = emptyList(),
    val meetResults: List<MeetResult> = emptyList(),
    val cachedAt: Long = System.currentTimeMillis(),
)

class SwimCache(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }

    fun load(userId: String): CachedSwimData? {
        val raw = prefs.getString(cacheKey(userId), null) ?: return null
        return runCatching { json.decodeFromString<CachedSwimData>(raw) }.getOrNull()
    }

    fun save(userId: String, data: CachedSwimData) {
        prefs.edit()
            .putString(cacheKey(userId), json.encodeToString(data))
            .apply()
    }

    fun clear(userId: String) {
        prefs.edit().remove(cacheKey(userId)).apply()
    }

    fun clearAll() {
        prefs.edit().clear().apply()
    }

    private fun cacheKey(userId: String) = "swim_data_$userId"

    companion object {
        private const val PREFS_NAME = "swimiq_cache"
    }
}
