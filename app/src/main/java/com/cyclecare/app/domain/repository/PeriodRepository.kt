package com.cyclecare.app.domain.repository

import com.cyclecare.app.domain.model.CycleInsights
import com.cyclecare.app.domain.model.CyclePrediction
import com.cyclecare.app.domain.model.Period
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

interface PeriodRepository {
    fun getAllPeriods(): Flow<List<Period>>
    suspend fun getPeriodById(id: Long): Period?
    suspend fun insertPeriod(period: Period): Long
    suspend fun updatePeriod(period: Period)
    suspend fun deletePeriod(period: Period)
    suspend fun predictNextCycle(): CyclePrediction?
    suspend fun getCycleInsights(): CycleInsights?
    suspend fun getPeriodsInRange(startDate: LocalDate, endDate: LocalDate): List<Period>
}
