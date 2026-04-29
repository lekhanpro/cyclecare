package com.cyclecare.app.domain.engine

import com.cyclecare.app.domain.model.Period
import com.cyclecare.app.domain.model.PredictionResult
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.pow
import kotlin.math.sqrt

@Singleton
class CyclePredictionEngine @Inject constructor() {

    fun buildPrediction(
        periods: List<Period>,
        referenceDate: LocalDate = LocalDate.now(),
        fallbackCycleLength: Int = 28,
        fallbackPeriodLength: Int = 5,
        lutealPhaseLength: Int = 14
    ): PredictionResult? {
        val normalized = periods
            .sortedByDescending { it.startDate }
            .distinctBy { it.startDate }

        if (normalized.isEmpty()) return null

        val cycleLengths = normalized
            .zipWithNext { current, previous ->
                ChronoUnit.DAYS.between(previous.startDate, current.startDate).toInt()
            }
            .filter { it in 15..90 }

        val averageCycleLength = when {
            cycleLengths.isEmpty() -> fallbackCycleLength
            cycleLengths.size < 3 -> cycleLengths.average().toInt().coerceIn(21, 40)
            else -> weightedCycleAverage(cycleLengths)
        }

        val periodLengths = normalized
            .mapNotNull { record ->
                record.endDate?.let {
                    ChronoUnit.DAYS.between(record.startDate, it).toInt() + 1
                }
            }
            .filter { it in 1..14 }

        val averagePeriodLength = if (periodLengths.isEmpty()) {
            fallbackPeriodLength
        } else {
            periodLengths.average().toInt().coerceIn(2, 10)
        }

        val lastStart = normalized.first().startDate
        val nextPeriodStart = if (lastStart.isAfter(referenceDate)) {
            lastStart
        } else {
            var predicted = lastStart
            while (!predicted.isAfter(referenceDate)) {
                predicted = predicted.plusDays(averageCycleLength.toLong())
            }
            predicted
        }

        val nextPeriodEnd = nextPeriodStart.plusDays((averagePeriodLength - 1).toLong())
        val ovulationDate = nextPeriodStart.minusDays(lutealPhaseLength.toLong())
        val fertileWindowStart = ovulationDate.minusDays(5)
        val fertileWindowEnd = ovulationDate.plusDays(1)

        val stdDeviation = standardDeviation(cycleLengths)
        val variabilityScore = (1f - (stdDeviation / 12f)).coerceIn(0.05f, 1f)
        val sampleScore = (cycleLengths.size / 6f).coerceIn(0.25f, 1f)
        val confidenceScore = (variabilityScore * 0.7f + sampleScore * 0.3f).coerceIn(0.1f, 0.99f)

        return PredictionResult(
            nextPeriodStart = nextPeriodStart,
            nextPeriodEnd = nextPeriodEnd,
            ovulationDate = ovulationDate,
            fertileWindowStart = fertileWindowStart,
            fertileWindowEnd = fertileWindowEnd,
            averageCycleLength = averageCycleLength,
            averagePeriodLength = averagePeriodLength,
            variabilityScore = variabilityScore,
            confidenceScore = confidenceScore,
            isIrregular = stdDeviation >= 4.5f,
            cycleLengthStdDeviation = stdDeviation
        )
    }

    private fun weightedCycleAverage(cycleLengths: List<Int>): Int {
        val recentFirst = cycleLengths
        var weight = recentFirst.size.toFloat()
        var weightedTotal = 0f
        var totalWeight = 0f
        recentFirst.forEach { length ->
            weightedTotal += length * weight
            totalWeight += weight
            weight = (weight - 1f).coerceAtLeast(1f)
        }
        return (weightedTotal / totalWeight).toInt().coerceIn(21, 40)
    }

    private fun standardDeviation(values: List<Int>): Float {
        if (values.isEmpty()) return 0f
        val mean = values.average()
        val variance = values.map { (it - mean).pow(2) }.average()
        return sqrt(variance).toFloat()
    }
}
