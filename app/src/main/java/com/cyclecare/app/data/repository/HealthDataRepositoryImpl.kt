package com.cyclecare.app.data.repository

import com.cyclecare.app.data.local.dao.HealthDataDao
import com.cyclecare.app.data.local.entity.HealthDataEntity
import com.cyclecare.app.domain.model.HealthData
import com.cyclecare.app.domain.repository.HealthDataRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDate
import javax.inject.Inject

class HealthDataRepositoryImpl @Inject constructor(
    private val healthDataDao: HealthDataDao
) : HealthDataRepository {
    
    override fun getAllHealthData(): Flow<List<HealthData>> {
        return healthDataDao.getAllHealthData().map { entities ->
            entities.map { it.toDomain() }
        }
    }
    
    override suspend fun getHealthDataByDate(date: LocalDate): HealthData? {
        return healthDataDao.getHealthDataByDate(date.toString())?.toDomain()
    }
    
    override fun getHealthDataInRange(startDate: LocalDate, endDate: LocalDate): Flow<List<HealthData>> {
        return healthDataDao.getHealthDataInRange(startDate.toString(), endDate.toString())
            .map { entities -> entities.map { it.toDomain() } }
    }
    
    override suspend fun insertHealthData(healthData: HealthData): Long {
        return healthDataDao.insertHealthData(healthData.toEntity())
    }
    
    override suspend fun updateHealthData(healthData: HealthData) {
        healthDataDao.updateHealthData(healthData.toEntity())
    }
    
    override suspend fun deleteHealthData(healthData: HealthData) {
        healthDataDao.deleteHealthData(healthData.toEntity())
    }
    
    private fun HealthDataEntity.toDomain(): HealthData {
        return HealthData(
            id = id,
            date = LocalDate.parse(date),
            weight = weight,
            bmi = bmi,
            bloodPressureSystolic = bloodPressureSystolic,
            bloodPressureDiastolic = bloodPressureDiastolic,
            heartRate = heartRate,
            medications = medications.split(",").filter { it.isNotBlank() },
            supplements = supplements.split(",").filter { it.isNotBlank() }
        )
    }
    
    private fun HealthData.toEntity(): HealthDataEntity {
        return HealthDataEntity(
            id = id,
            date = date.toString(),
            weight = weight,
            bmi = bmi,
            bloodPressureSystolic = bloodPressureSystolic,
            bloodPressureDiastolic = bloodPressureDiastolic,
            heartRate = heartRate,
            medications = medications.joinToString(","),
            supplements = supplements.joinToString(",")
        )
    }
}
