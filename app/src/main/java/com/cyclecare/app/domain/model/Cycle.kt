package com.cyclecare.app.domain.model

import java.time.LocalDate

data class Cycle(
    val id: Long = 0,
    val startDate: LocalDate,
    val endDate: LocalDate?,
    val length: Int,
    val periodLength: Int,
    val ovulationDate: LocalDate?,
    val fertileWindowStart: LocalDate?,
    val fertileWindowEnd: LocalDate?
)

data class CyclePrediction(
    val nextPeriodStart: LocalDate,
    val nextPeriodEnd: LocalDate,
    val nextOvulation: LocalDate,
    val nextFertileWindowStart: LocalDate,
    val nextFertileWindowEnd: LocalDate,
    val confidence: Float,
    val variabilityScore: Float,
    val isIrregular: Boolean,
    val averageCycleLength: Int,
    val averagePeriodLength: Int,
    val cycleLengthStdDeviation: Float
)

data class CycleInsights(
    val averageCycleLength: Int,
    val averagePeriodLength: Int,
    val cycleRegularity: Float,
    val totalCyclesTracked: Int,
    val commonSymptoms: List<Symptom>,
    val cycleLengthTrend: List<Int> = emptyList(),
    val periodLengthTrend: List<Int> = emptyList()
)

data class PredictionResult(
    val nextPeriodStart: LocalDate,
    val nextPeriodEnd: LocalDate,
    val ovulationDate: LocalDate,
    val fertileWindowStart: LocalDate,
    val fertileWindowEnd: LocalDate,
    val averageCycleLength: Int,
    val averagePeriodLength: Int,
    val variabilityScore: Float,
    val confidenceScore: Float,
    val isIrregular: Boolean,
    val cycleLengthStdDeviation: Float
) {
    fun toCyclePrediction(): CyclePrediction {
        return CyclePrediction(
            nextPeriodStart = nextPeriodStart,
            nextPeriodEnd = nextPeriodEnd,
            nextOvulation = ovulationDate,
            nextFertileWindowStart = fertileWindowStart,
            nextFertileWindowEnd = fertileWindowEnd,
            confidence = confidenceScore,
            variabilityScore = variabilityScore,
            isIrregular = isIrregular,
            averageCycleLength = averageCycleLength,
            averagePeriodLength = averagePeriodLength,
            cycleLengthStdDeviation = cycleLengthStdDeviation
        )
    }
}
