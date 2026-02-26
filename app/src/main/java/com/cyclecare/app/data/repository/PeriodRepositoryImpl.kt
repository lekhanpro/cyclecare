package com.cyclecare.app.data.repository

import com.cyclecare.app.data.local.dao.PeriodDao
import com.cyclecare.app.data.local.entity.PeriodEntity
import com.cyclecare.app.domain.model.*
import com.cyclecare.app.domain.repository.PeriodRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import javax.inject.Inject
import kotlin.math.abs

class PeriodRepositoryImpl @Inject constructor(
    private val periodDao: PeriodDao
) : PeriodRepository {

    override fun getAllPeriods(): Flow<List<Period>> =
        periodDao.getAllPeriods().map { entities ->
            entities.map { it.toDomain() }
        }

    override suspend fun getPeriodById(id: Long): Period? =
        periodDao.getPeriodById(id)?.toDomain()

    override suspend fun insertPeriod(period: Period): Long =
        periodDao.insertPeriod(period.toEntity())

    override suspend fun updatePeriod(period: Period) =
        periodDao.updatePeriod(period.toEntity())

    override suspend fun deletePeriod(period: Period) =
        periodDao.deletePeriod(period.toEntity())

    override suspend fun getPeriodsInRange(startDate: LocalDate, endDate: LocalDate): List<Period> =
        periodDao.getPeriodsInRange(startDate, endDate).map { it.toDomain() }

    override suspend fun predictNextCycle(): CyclePrediction? {
        val recentPeriods = periodDao.getRecentPeriods(6)
        if (recentPeriods.size < 3) return null

        // Calculate cycle lengths
        val cycleLengths = mutableListOf<Long>()
        for (i in 0 until recentPeriods.size - 1) {
            val current = recentPeriods[i].startDate
            val next = recentPeriods[i + 1].startDate
            cycleLengths.add(ChronoUnit.DAYS.between(next, current))
        }

        val avgCycleLength = cycleLengths.average().toLong()
        
        // Calculate period lengths
        val periodLengths = recentPeriods.mapNotNull { period ->
            period.endDate?.let { ChronoUnit.DAYS.between(period.startDate, it) + 1 }
        }
        val avgPeriodLength = if (periodLengths.isNotEmpty()) {
            periodLengths.average().toLong()
        } else {
            5L // Default period length
        }

        // Predict next cycle
        val lastPeriodStart = recentPeriods.first().startDate
        val nextPeriodStart = lastPeriodStart.plusDays(avgCycleLength)
        val nextPeriodEnd = nextPeriodStart.plusDays(avgPeriodLength - 1)
        
        // Ovulation typically occurs 14 days before next period
        val nextOvulation = nextPeriodStart.minusDays(14)
        
        // Fertile window: 5 days before ovulation to 1 day after
        val fertileStart = nextOvulation.minusDays(5)
        val fertileEnd = nextOvulation.plusDays(1)

        // Calculate confidence based on cycle regularity
        val cycleVariance = cycleLengths.map { abs(it - avgCycleLength) }.average()
        val confidence = when {
            cycleVariance <= 2 -> 0.95f
            cycleVariance <= 4 -> 0.85f
            cycleVariance <= 6 -> 0.70f
            else -> 0.50f
        }

        return CyclePrediction(
            nextPeriodStart = nextPeriodStart,
            nextPeriodEnd = nextPeriodEnd,
            nextOvulation = nextOvulation,
            nextFertileWindowStart = fertileStart,
            nextFertileWindowEnd = fertileEnd,
            confidence = confidence
        )
    }

    override suspend fun getCycleInsights(): CycleInsights? {
        val allPeriods = periodDao.getRecentPeriods(12)
        if (allPeriods.size < 2) return null

        // Calculate average cycle length
        val cycleLengths = mutableListOf<Long>()
        for (i in 0 until allPeriods.size - 1) {
            val current = allPeriods[i].startDate
            val next = allPeriods[i + 1].startDate
            cycleLengths.add(ChronoUnit.DAYS.between(next, current))
        }
        val avgCycleLength = cycleLengths.average().toInt()

        // Calculate average period length
        val periodLengths = allPeriods.mapNotNull { period ->
            period.endDate?.let { ChronoUnit.DAYS.between(period.startDate, it) + 1 }
        }
        val avgPeriodLength = if (periodLengths.isNotEmpty()) {
            periodLengths.average().toInt()
        } else {
            5
        }

        // Calculate cycle regularity (0.0 to 1.0)
        val cycleVariance = cycleLengths.map { abs(it - avgCycleLength) }.average()
        val regularity = when {
            cycleVariance <= 2 -> 1.0f
            cycleVariance <= 4 -> 0.8f
            cycleVariance <= 6 -> 0.6f
            else -> 0.4f
        }

        // Find common symptoms
        val symptomCounts = mutableMapOf<String, Int>()
        allPeriods.forEach { period ->
            period.symptoms.forEach { symptom ->
                symptomCounts[symptom] = symptomCounts.getOrDefault(symptom, 0) + 1
            }
        }
        val commonSymptoms = symptomCounts.entries
            .sortedByDescending { it.value }
            .take(5)
            .mapNotNull { 
                try {
                    Symptom.valueOf(it.key)
                } catch (e: Exception) {
                    null
                }
            }

        return CycleInsights(
            averageCycleLength = avgCycleLength,
            averagePeriodLength = avgPeriodLength,
            cycleRegularity = regularity,
            totalCyclesTracked = allPeriods.size,
            commonSymptoms = commonSymptoms
        )
    }

    private fun PeriodEntity.toDomain() = Period(
        id = id,
        startDate = startDate,
        endDate = endDate,
        flow = FlowIntensity.valueOf(flow),
        symptoms = symptoms.mapNotNull { 
            try {
                Symptom.valueOf(it)
            } catch (e: Exception) {
                null
            }
        },
        notes = notes
    )

    private fun Period.toEntity() = PeriodEntity(
        id = id,
        startDate = startDate,
        endDate = endDate,
        flow = flow.name,
        symptoms = symptoms.map { it.name },
        notes = notes
    )
}
