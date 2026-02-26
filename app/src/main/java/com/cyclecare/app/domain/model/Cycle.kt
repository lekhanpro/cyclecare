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
    val confidence: Float // 0.0 to 1.0
)

data class CycleInsights(
    val averageCycleLength: Int,
    val averagePeriodLength: Int,
    val cycleRegularity: Float, // 0.0 to 1.0
    val totalCyclesTracked: Int,
    val commonSymptoms: List<Symptom>
)
