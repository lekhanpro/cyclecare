package com.cyclecare.app.domain.repository

import com.cyclecare.app.domain.model.HealthData
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

interface HealthDataRepository {
    fun getAllHealthData(): Flow<List<HealthData>>
    suspend fun getHealthDataByDate(date: LocalDate): HealthData?
    fun getHealthDataInRange(startDate: LocalDate, endDate: LocalDate): Flow<List<HealthData>>
    suspend fun insertHealthData(healthData: HealthData): Long
    suspend fun updateHealthData(healthData: HealthData)
    suspend fun deleteHealthData(healthData: HealthData)
}
