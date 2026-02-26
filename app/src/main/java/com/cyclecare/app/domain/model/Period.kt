package com.cyclecare.app.domain.model

import java.time.LocalDate

data class Period(
    val id: Long = 0,
    val startDate: LocalDate,
    val endDate: LocalDate?,
    val flow: FlowIntensity = FlowIntensity.MEDIUM,
    val symptoms: List<Symptom> = emptyList(),
    val notes: String = ""
)

enum class FlowIntensity {
    SPOTTING,
    LIGHT,
    MEDIUM,
    HEAVY
}

enum class Symptom {
    CRAMPS,
    HEADACHE,
    MOOD_SWINGS,
    FATIGUE,
    BLOATING,
    ACNE,
    BACK_PAIN,
    NAUSEA,
    BREAST_TENDERNESS,
    ANXIETY,
    IRRITABILITY,
    FOOD_CRAVINGS
}
