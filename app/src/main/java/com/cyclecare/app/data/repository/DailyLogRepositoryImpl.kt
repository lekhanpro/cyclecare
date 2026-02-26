package com.cyclecare.app.data.repository

import com.cyclecare.app.data.local.dao.DailyLogDao
import com.cyclecare.app.data.local.entity.DailyLogEntity
import com.cyclecare.app.domain.model.*
import com.cyclecare.app.domain.repository.DailyLogRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDate
import javax.inject.Inject

class DailyLogRepositoryImpl @Inject constructor(
    private val dailyLogDao: DailyLogDao
) : DailyLogRepository {

    override fun getAllLogs(): Flow<List<DailyLog>> =
        dailyLogDao.getAllLogs().map { entities ->
            entities.map { it.toDomain() }
        }

    override suspend fun getLogByDate(date: LocalDate): DailyLog? =
        dailyLogDao.getLogByDate(date)?.toDomain()

    override suspend fun insertLog(log: DailyLog): Long =
        dailyLogDao.insertLog(log.toEntity())

    override suspend fun updateLog(log: DailyLog) =
        dailyLogDao.updateLog(log.toEntity())

    override suspend fun deleteLog(log: DailyLog) =
        dailyLogDao.deleteLog(log.toEntity())

    override suspend fun getLogsInRange(startDate: LocalDate, endDate: LocalDate): List<DailyLog> =
        dailyLogDao.getLogsInRange(startDate, endDate).map { it.toDomain() }

    private fun DailyLogEntity.toDomain() = DailyLog(
        id = id,
        date = date,
        mood = mood?.let { 
            try {
                Mood.valueOf(it)
            } catch (e: Exception) {
                null
            }
        },
        symptoms = symptoms.mapNotNull { 
            try {
                Symptom.valueOf(it)
            } catch (e: Exception) {
                null
            }
        },
        temperature = temperature,
        cervicalMucus = cervicalMucus?.let { 
            try {
                CervicalMucusType.valueOf(it)
            } catch (e: Exception) {
                null
            }
        },
        sexualActivity = sexualActivity,
        waterIntake = waterIntake,
        sleepHours = sleepHours,
        exerciseMinutes = exerciseMinutes,
        notes = notes
    )

    private fun DailyLog.toEntity() = DailyLogEntity(
        id = id,
        date = date,
        mood = mood?.name,
        symptoms = symptoms.map { it.name },
        temperature = temperature,
        cervicalMucus = cervicalMucus?.name,
        sexualActivity = sexualActivity,
        waterIntake = waterIntake,
        sleepHours = sleepHours,
        exerciseMinutes = exerciseMinutes,
        notes = notes
    )
}
