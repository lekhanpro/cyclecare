package com.cyclecare.app.domain.model

import java.time.LocalDate

data class DailyLog(
    val id: Long = 0,
    val date: LocalDate,
    val flow: FlowIntensity? = null,
    val mood: Mood? = null,
    val symptoms: List<Symptom> = emptyList(),
    val discharge: DischargeType? = null,
    val weightKg: Float? = null,
    val temperature: Float? = null,
    val sleepHours: Float? = null,
    val waterMl: Int = 0,
    val intimacy: IntimacyType = IntimacyType.NONE,
    val ovulationTest: TestResult = TestResult.NOT_TAKEN,
    val pregnancyTest: TestResult = TestResult.NOT_TAKEN,
    val cervicalMucus: CervicalMucusType? = null,
    val sexualActivity: Boolean = false,
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

enum class DischargeType {
    DRY,
    STICKY,
    CREAMY,
    WATERY,
    EGG_WHITE,
    BLOODY,
    UNUSUAL
}

enum class IntimacyType {
    NONE,
    PROTECTED,
    UNPROTECTED,
    OTHER
}

enum class TestResult {
    NOT_TAKEN,
    NEGATIVE,
    POSITIVE,
    INCONCLUSIVE
}
