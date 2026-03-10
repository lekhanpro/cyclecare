package com.cyclecare.app.domain.model

import java.time.LocalDate

data class Period(
    val id: Long = 0,
    val startDate: LocalDate,
    val endDate: LocalDate?,
    val flow: FlowIntensity = FlowIntensity.MEDIUM,
    val symptoms: List<Symptom> = emptyList(),
    val notes: String = "",
    val source: RecordSource = RecordSource.MANUAL
)

data class CycleRecord(
    val id: Long = 0,
    val startDate: LocalDate,
    val endDate: LocalDate?,
    val flow: FlowIntensity = FlowIntensity.MEDIUM,
    val symptoms: List<Symptom> = emptyList(),
    val notes: String = "",
    val source: RecordSource = RecordSource.MANUAL
)

enum class FlowIntensity {
    SPOTTING,
    LIGHT,
    MEDIUM,
    HEAVY
}

enum class RecordSource {
    MANUAL,
    IMPORT,
    EDIT
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
    FOOD_CRAVINGS,
    LOWER_BACK_PAIN,
    INSOMNIA,
    LOW_ENERGY,
    APPETITE_CHANGES
}
