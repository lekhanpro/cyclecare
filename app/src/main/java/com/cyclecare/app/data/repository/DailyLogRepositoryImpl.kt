package com.cyclecare.app.data.repository

import com.cyclecare.app.data.local.dao.DailyLogDao
import com.cyclecare.app.data.local.entity.DailyLogEntity
import com.cyclecare.app.domain.model.CervicalMucusType
import com.cyclecare.app.domain.model.DailyLog
import com.cyclecare.app.domain.model.DischargeType
import com.cyclecare.app.domain.model.FlowIntensity
import com.cyclecare.app.domain.model.IntimacyType
import com.cyclecare.app.domain.model.Mood
import com.cyclecare.app.domain.model.Symptom
import com.cyclecare.app.domain.model.TestResult
import com.cyclecare.app.domain.repository.DailyLogRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDate
import javax.inject.Inject

class DailyLogRepositoryImpl @Inject constructor(
    private val dailyLogDao: DailyLogDao
) : DailyLogRepository {

    override fun getAllLogs(): Flow<List<DailyLog>> =
        dailyLogDao.getAllLogs().map { entities -> entities.map { it.toDomain() } }

    override suspend fun getAllLogsList(): List<DailyLog> =
        dailyLogDao.getAllLogsList().map { it.toDomain() }

    override suspend fun getLogByDate(date: LocalDate): DailyLog? =
        dailyLogDao.getLogByDate(date)?.toDomain()

    override suspend fun insertLog(log: DailyLog): Long =
        dailyLogDao.insertLog(log.toEntity())

    override suspend fun updateLog(log: DailyLog) =
        dailyLogDao.updateLog(log.toEntity())

    override suspend fun upsertLog(log: DailyLog): Long {
        val existing = dailyLogDao.getLogByDate(log.date)
        return if (existing == null) {
            insertLog(log)
        } else {
            updateLog(log.copy(id = existing.id))
            existing.id
        }
    }

    override suspend fun deleteLog(log: DailyLog) =
        dailyLogDao.deleteLog(log.toEntity())

    override suspend fun getLogsInRange(startDate: LocalDate, endDate: LocalDate): List<DailyLog> =
        dailyLogDao.getLogsInRange(startDate, endDate).map { it.toDomain() }

    private fun DailyLogEntity.toDomain() = DailyLog(
        id = id,
        date = date,
        flow = flow?.let { runCatching { FlowIntensity.valueOf(it) }.getOrNull() },
        mood = mood?.let { runCatching { Mood.valueOf(it) }.getOrNull() },
        symptoms = symptoms.mapNotNull { runCatching { Symptom.valueOf(it) }.getOrNull() },
        discharge = discharge?.let { runCatching { DischargeType.valueOf(it) }.getOrNull() },
        weightKg = weightKg,
        temperature = temperature,
        sleepHours = sleepHours,
        waterMl = waterMl,
        intimacy = runCatching { IntimacyType.valueOf(intimacy) }.getOrDefault(IntimacyType.NONE),
        ovulationTest = runCatching { TestResult.valueOf(ovulationTest) }.getOrDefault(TestResult.NOT_TAKEN),
        pregnancyTest = runCatching { TestResult.valueOf(pregnancyTest) }.getOrDefault(TestResult.NOT_TAKEN),
        cervicalMucus = cervicalMucus?.let { runCatching { CervicalMucusType.valueOf(it) }.getOrNull() },
        sexualActivity = sexualActivity,
        exerciseMinutes = exerciseMinutes,
        notes = notes
    )

    private fun DailyLog.toEntity() = DailyLogEntity(
        id = id,
        date = date,
        flow = flow?.name,
        mood = mood?.name,
        symptoms = symptoms.map { it.name },
        discharge = discharge?.name,
        weightKg = weightKg,
        temperature = temperature,
        ovulationTest = ovulationTest.name,
        pregnancyTest = pregnancyTest.name,
        intimacy = intimacy.name,
        waterMl = waterMl,
        cervicalMucus = cervicalMucus?.name,
        sexualActivity = sexualActivity,
        sleepHours = sleepHours,
        exerciseMinutes = exerciseMinutes,
        notes = notes
    )
}
