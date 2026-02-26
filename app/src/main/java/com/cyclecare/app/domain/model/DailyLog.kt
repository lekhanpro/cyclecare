package com.cyclecare.app.domain.model

import java.time.LocalDate

data class DailyLog(
    val id: Long = 0,
    val date: LocalDate,
    val mood: Mood? = null,
    val symptoms: List<Symptom> = emptyList(),
    val temperature: Float? = null,
    val cervicalMucus: CervicalMucusType? = null,
    val sexualActivity: Boolean = false,
    val waterIntake: Int = 0, // in glasses
    val sleepHours: Float? = null,
    val exerciseMinutes: Int = 0,
    val notes: String = ""
)

enum class Mood {
    HAPPY,
    SAD,
    ANXIOUS,
    IRRITABLE,
    CALM,
    ENERGETIC,
    TIRED,
    STRESSED
}

enum class CervicalMucusType {
    DRY,
    STICKY,
    CREAMY,
    WATERY,
    EGG_WHITE
}
