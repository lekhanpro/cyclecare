package com.cyclecare.app.domain.model

import java.time.LocalDate

data class HealthData(
    val id: Long = 0,
    val date: LocalDate,
    val weight: Float? = null,
    val bmi: Float? = null,
    val bloodPressureSystolic: Int? = null,
    val bloodPressureDiastolic: Int? = null,
    val heartRate: Int? = null,
    val medications: List<String> = emptyList(),
    val supplements: List<String> = emptyList()
)

data class PregnancyData(
    val id: Long = 0,
    val conceptionDate: LocalDate? = null,
    val dueDate: LocalDate? = null,
    val pregnancyTestDate: LocalDate? = null,
    val pregnancyTestResult: Boolean? = null,
    val currentWeek: Int = 0,
    val symptoms: List<String> = emptyList(),
    val notes: String = ""
)

data class BirthControlData(
    val id: Long = 0,
    val type: BirthControlType,
    val startDate: LocalDate,
    val endDate: LocalDate? = null,
    val pillTime: String? = null,
    val reminderEnabled: Boolean = true,
    val notes: String = ""
)

enum class BirthControlType {
    PILL,
    PATCH,
    RING,
    IUD,
    IMPLANT,
    INJECTION,
    CONDOM,
    OTHER
}
