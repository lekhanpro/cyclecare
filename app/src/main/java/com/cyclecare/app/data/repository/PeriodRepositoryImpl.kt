package com.cyclecare.app.data.repository

import com.cyclecare.app.data.local.dao.PeriodDao
import com.cyclecare.app.data.local.entity.PeriodEntity
import com.cyclecare.app.domain.engine.CyclePredictionEngine
import com.cyclecare.app.domain.model.CycleInsights
import com.cyclecare.app.domain.model.CyclePrediction
import com.cyclecare.app.domain.model.FlowIntensity
import com.cyclecare.app.domain.model.Period
import com.cyclecare.app.domain.model.PredictionResult
import com.cyclecare.app.domain.model.RecordSource
import com.cyclecare.app.domain.model.Symptom
import com.cyclecare.app.domain.repository.PeriodRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import javax.inject.Inject

class PeriodRepositoryImpl @Inject constructor(
    private val periodDao: PeriodDao,
    private val cyclePredictionEngine: CyclePredictionEngine
) : PeriodRepository {

    override fun getAllPeriods(): Flow<List<Period>> =
        periodDao.getAllPeriods().map { entities -> entities.map { it.toDomain() } }

    override suspend fun getAllPeriodsList(): List<Period> =
        periodDao.getAllPeriodsList().map { it.toDomain() }

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
        return predict()?.toCyclePrediction()
    }

    override suspend fun predict(referenceDate: LocalDate): PredictionResult? {
        val periods = periodDao.getRecentPeriods(18).map { it.toDomain() }
        return cyclePredictionEngine.buildPrediction(
            periods = periods,
            referenceDate = referenceDate
        )
    }

    override suspend fun getCycleInsights(): CycleInsights? {
        val periods = periodDao.getRecentPeriods(18).map { it.toDomain() }
        if (periods.size < 2) return null

        val cycleLengths = periods
            .zipWithNext { current, previous ->
                ChronoUnit.DAYS.between(previous.startDate, current.startDate).toInt()
            }
            .filter { it in 15..90 }

        val periodLengths = periods
            .mapNotNull { period ->
                period.endDate?.let {
                    ChronoUnit.DAYS.between(period.startDate, it).toInt() + 1
                }
            }
            .filter { it in 1..14 }

        if (cycleLengths.isEmpty()) return null

        val averageCycleLength = cycleLengths.average().toInt()
        val averagePeriodLength = if (periodLengths.isEmpty()) 5 else periodLengths.average().toInt()
        val regularity = (1f - (standardDeviation(cycleLengths) / 12f)).coerceIn(0.05f, 1f)

        val symptomCounts = mutableMapOf<Symptom, Int>()
        periods.forEach { period ->
            period.symptoms.forEach { symptom ->
                symptomCounts[symptom] = symptomCounts.getOrDefault(symptom, 0) + 1
            }
        }

        return CycleInsights(
            averageCycleLength = averageCycleLength,
            averagePeriodLength = averagePeriodLength,
            cycleRegularity = regularity,
            totalCyclesTracked = periods.size,
            commonSymptoms = symptomCounts.entries
                .sortedByDescending { it.value }
                .take(6)
                .map { it.key },
            cycleLengthTrend = cycleLengths.take(8).reversed(),
            periodLengthTrend = periodLengths.take(8).reversed()
        )
    }

    private fun standardDeviation(values: List<Int>): Float {
        val mean = values.average()
        val variance = values.map { (it - mean) * (it - mean) }.average()
        return kotlin.math.sqrt(variance).toFloat()
    }

    private fun PeriodEntity.toDomain() = Period(
        id = id,
        startDate = startDate,
        endDate = endDate,
        flow = runCatching { FlowIntensity.valueOf(flow) }.getOrDefault(FlowIntensity.MEDIUM),
        symptoms = symptoms.mapNotNull { symptom -> runCatching { Symptom.valueOf(symptom) }.getOrNull() },
        notes = notes,
        source = runCatching { RecordSource.valueOf(source) }.getOrDefault(RecordSource.MANUAL)
    )

    private fun Period.toEntity() = PeriodEntity(
        id = id,
        startDate = startDate,
        endDate = endDate,
        flow = flow.name,
        symptoms = symptoms.map { it.name },
        notes = notes,
        source = source.name
    )
}
