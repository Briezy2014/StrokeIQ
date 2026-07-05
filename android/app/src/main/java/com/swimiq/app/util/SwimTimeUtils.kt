package com.swimiq.app.util

object SwimTimeUtils {
    fun toSeconds(timeText: String): Double {
        val trimmed = timeText.trim()
        if (trimmed.isEmpty()) throw IllegalArgumentException("Time is required.")

        return if (trimmed.contains(":")) {
            val parts = trimmed.split(":")
            if (parts.size != 2) throw IllegalArgumentException("Use M:SS.hh format.")
            val minutes = parts[0].toInt()
            val seconds = parts[1].toDouble()
            ((minutes * 60) + seconds).let { (it * 100).toInt() / 100.0 }
        } else {
            trimmed.toDouble().let { (it * 100).toInt() / 100.0 }
        }
    }

    fun formatSeconds(seconds: Double): String {
        val minutes = (seconds / 60).toInt()
        val remaining = seconds % 60
        return if (minutes > 0) {
            String.format("%d:%05.2f", minutes, remaining)
        } else {
            String.format("%.2f", seconds)
        }
    }
}
